//
// Created by Maarten Billemont on 2015-09-24.
// Copyright (c) 2015 Maarten Billemont. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit

class MapViewController: UIViewController, UIGestureRecognizerDelegate, UISearchBarDelegate, CLLocationManagerDelegate {
    let locationManager: CLLocationManager = CLLocationManager()
    let geoCoder:        CLGeocoder        = CLGeocoder()

    @IBOutlet var mapView:          MKMapView!
    @IBOutlet var activityView:     UIActivityIndicatorView!
    @IBOutlet var searchBar:        UISearchBar!
    var           searchAnnotation: MKAnnotation?

    @IBOutlet var rightSlideOut:              UIView!
    @IBOutlet var rightSlideOutConstraint:    NSLayoutConstraint!
    @IBOutlet var screenEdgePanRecognizer:    UIScreenEdgePanGestureRecognizer!
    @IBOutlet var rightSlideOutPanRecognizer: UIPanGestureRecognizer!

    override func viewDidLoad() {
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()

        searchBar.delegate = self

        super.viewDidLoad()
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear( animated )
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear( animated )

        activityView.stopAnimating()
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear( animated )

        activityView.startAnimating()
    }

    /* UISearchBarDelegate */

    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        let region   = mapView.region
        let regionNW = CLLocation( latitude: region.center.latitude - region.span.latitudeDelta * 0.5,
                longitude: region.center.longitude - region.span.longitudeDelta * 0.5 )
        let regionSE = CLLocation( latitude: region.center.latitude + region.span.latitudeDelta * 0.5,
                longitude: region.center.longitude + region.span.longitudeDelta * 0.5 )
        let clRegion = CLCircularRegion( center: mapView.region.center, radius: regionNW.distanceFromLocation( regionSE ) / 2,
                identifier: "search" )

        activityView.startAnimating()
        geoCoder.geocodeAddressString( searchBar.text!.stringByAppendingString(", Canada"), inRegion: clRegion, completionHandler: {
            (placemarks: [CLPlacemark]?, error: NSError?) in
            if let _searchAnnotation = self.searchAnnotation {
                self.mapView.removeAnnotation( _searchAnnotation )
            }
            if let _error = error {
                NSLog( "error: %@", _error )
            }
            if let _placemarks = placemarks where _placemarks.count > 0 {
                self.searchAnnotation = MKPlacemark( placemark: _placemarks[0] )
            }
            else {
                self.searchAnnotation = nil
            }
            if let _searchAnnotation = self.searchAnnotation {
                self.mapView.addAnnotation( _searchAnnotation )
                self.mapView.showAnnotations( [ _searchAnnotation ], animated: true )
            }

            self.activityView.stopAnimating()
        } )
    }

    /* CLLocationManagerDelegate */

    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        switch status {
            case .NotDetermined, .Restricted, .Denied:
                mapView.showsUserLocation = false

            case .AuthorizedAlways, .AuthorizedWhenInUse:
                mapView.showsUserLocation = true
        }
    }

    /* UIGestureRecognizerDelegate */

    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer == screenEdgePanRecognizer {
            return true
        }

        return false
    }

    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailByGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer == screenEdgePanRecognizer {
            return true
        }

        return false
    }

    /* Actions */

    @IBAction func didPan(sender: UIPanGestureRecognizer) {
        let rightSlideOutTotal = -rightSlideOut.bounds.size.width

        if (sender == rightSlideOutPanRecognizer) {
            setConstraintConstantFromGesture( rightSlideOutConstraint,
                    gestureState: sender.state, rest: rightSlideOutTotal, target: 0,
                    current: rightSlideOutTotal + sender.translationInView( rightSlideOut ).x )
        }
        else if (sender == screenEdgePanRecognizer) {
            setConstraintConstantFromGesture( rightSlideOutConstraint,
                    gestureState: sender.state, rest: 0, target: rightSlideOutTotal,
                    current: sender.translationInView( rightSlideOut ).x )
        }
    }

    /* Private */

    func setConstraintConstantFromGesture(constraint: NSLayoutConstraint!, gestureState: UIGestureRecognizerState,
                                          rest: CGFloat, target: CGFloat, var current: CGFloat) {
        if rest < target {
            current = min( target, max( rest, current ) )
        }
        else {
            current = min( rest, max( target, current ) )
        }

        switch gestureState {
            case .Possible:
                break

            case .Began:
                constraint.constant = current

            case .Changed:
                constraint.constant = current

            case .Ended:
                if abs( current - rest ) < abs( current - target ) {
                    constraint.constant = rest
                }
                else {
                    constraint.constant = target
                }

            case .Cancelled:
                constraint.constant = rest

            case .Failed:
                constraint.constant = rest
        }
    }
}

