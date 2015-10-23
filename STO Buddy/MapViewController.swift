//
// Created by Maarten Billemont on 2015-09-24.
// Copyright (c) 2015 Maarten Billemont. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit
import Alamofire
import HTMLReader

class MapViewController: UIViewController, UIGestureRecognizerDelegate, UISearchBarDelegate, CLLocationManagerDelegate, MKMapViewDelegate {
    let locationManager: CLLocationManager = CLLocationManager()
    let geoCoder:        CLGeocoder        = CLGeocoder()

    var mapSearchAnnotation: MKAnnotation? {
        willSet {
            if let searchAnnotation_ = mapSearchAnnotation {
                mapView.removeAnnotation( searchAnnotation_ )
            }
        }
        didSet {
            if let searchAnnotation_ = mapSearchAnnotation {
                mapView.addAnnotation( searchAnnotation_ )
                showAnnotations()
            }
        }
    }
    var mapRouteOverlay: MKPolyline? {
        willSet {
            if let mapRouteOverlay_ = mapRouteOverlay {
                mapView.removeOverlay( mapRouteOverlay_ )
            }
        }
        didSet {
            if let mapRouteOverlay_ = mapRouteOverlay {
                mapView.addOverlay( mapRouteOverlay_ )
            }
        }
    }

    let locationAnnotations: NSMutableOrderedSet = NSMutableOrderedSet()
    var route: Route? {
        didSet {
            rightSlideOutViewController.route = route

            self.view.layoutIfNeeded()
            UIView.animateWithDuration( 0.3, animations: {
                if self.route != nil {
                    self.rightSlideOutConstraint.constant = -self.rightSlideOut.bounds.size.width
                }
                else {
                    self.rightSlideOutConstraint.constant = 0
                }

                self.view.layoutIfNeeded()
            } )
        }
    }

    @IBOutlet var headerBlurView:              UIVisualEffectView!
    @IBOutlet var headerStackMarginConstraint: NSLayoutConstraint!
    @IBOutlet var searchBar:                   UISearchBar!
    @IBOutlet var routeLocationsStackView:     UIStackView!
    @IBOutlet var activityView:                UIActivityIndicatorView!
    @IBOutlet var mapView:                     MKMapView!
    @IBOutlet var toolBar:                     UIToolbar!

    @IBOutlet var rightSlideOutBlurView:       UIVisualEffectView!
    @IBOutlet var rightSlideOut:               UIView!
    @IBOutlet var rightSlideOutViewController: RouteViewController!
    @IBOutlet var rightSlideOutConstraint:     NSLayoutConstraint!
    @IBOutlet var screenEdgePanRecognizer:     UIScreenEdgePanGestureRecognizer!
    @IBOutlet var rightSlideOutPanRecognizer:  UIPanGestureRecognizer!

    override func viewDidLoad() {
        headerBlurView.layer.borderColor = UIColor.lightTextColor().CGColor
        headerBlurView.layer.borderWidth = 1
        headerBlurView.layer.shadowOpacity = 0.5
        headerBlurView.layer.shadowOffset = CGSizeMake( 0, -3 )

        rightSlideOutBlurView.layer.shadowOpacity = 0.5
        headerBlurView.layer.shadowOffset = CGSizeMake( -3, 0 )

        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()

        searchBar.delegate = self

        toolBar.items!.insert( MKUserTrackingBarButtonItem( mapView: self.mapView ), atIndex: 0 );

        rightSlideOutConstraint.constant = 0

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

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "rightSlideOut" {
            rightSlideOutViewController = segue.destinationViewController as! RouteViewController
        }

        super.prepareForSegue( segue, sender: sender )
    }

    /* MKMapViewDelegate */

    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        if let searchAnnotation_ = mapSearchAnnotation
        where searchAnnotation_ === annotation {
            let identifier               = "SearchAnnotation"
            var annotationView:
                    MKPinAnnotationView! = mapView.dequeueReusableAnnotationViewWithIdentifier( identifier ) as? MKPinAnnotationView
            if annotationView == nil {
                annotationView = MKPinAnnotationView( annotation: searchAnnotation_, reuseIdentifier: identifier )
            }

            annotationView.pinTintColor = MKPinAnnotationView.redPinColor()
            annotationView.animatesDrop = true
            annotationView.canShowCallout = true
            annotationView.rightCalloutAccessoryView = createAddRouteLocationButton( annotation )
            return annotationView
        }

        return nil
    }

    func mapView(mapView: MKMapView, rendererForOverlay overlay: MKOverlay) -> MKOverlayRenderer {
        if let mapRouteOverlay_ = self.mapRouteOverlay
        where mapRouteOverlay_ === overlay {
            let renderer = MKPolylineRenderer( polyline: mapRouteOverlay_ )
            renderer.strokeColor = UIColor.blueColor().colorWithAlphaComponent( 0.5 )
            renderer.lineWidth = 3
            renderer.lineDashPattern = [ 5, 5 ]
            return renderer
        }

        assert( false, "Unsupported overlay: \(overlay)" )
        return MKOverlayRenderer( overlay: overlay )
    }

    func mapView(mapView: MKMapView, didAddAnnotationViews views: [MKAnnotationView]) {
        for annotationView in views {
            if annotationView.annotation === mapView.userLocation {
                annotationView.rightCalloutAccessoryView = createAddRouteLocationButton( mapView.userLocation )

                showAnnotations()
            }
        }
    }


    /* UISearchBarDelegate */

    func searchBarTextDidBeginEditing(searchBar: UISearchBar) {
        searchBar.setShowsCancelButton( true, animated: true )
    }

    func searchBarTextDidEndEditing(searchBar: UISearchBar) {
        searchBar.setShowsCancelButton( false, animated: true )
    }

    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }

    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        let region   = mapView.region
        let regionNW = CLLocation( latitude: region.center.latitude - region.span.latitudeDelta * 0.5,
                longitude: region.center.longitude - region.span.longitudeDelta * 0.5 )
        let regionSE = CLLocation( latitude: region.center.latitude + region.span.latitudeDelta * 0.5,
                longitude: region.center.longitude + region.span.longitudeDelta * 0.5 )
        let clRegion = CLCircularRegion( center: mapView.region.center, radius: regionNW.distanceFromLocation( regionSE ) / 2,
                identifier: "search" )

        activityView.startAnimating()
        searchBar.resignFirstResponder()

        geoCoder.geocodeAddressString( searchBar.text!.stringByAppendingString( ", Canada" ), inRegion: clRegion, completionHandler: {
            (placemarks: [CLPlacemark]?, error: NSError?) in
            if let error_ = error {
                print( "ERROR: Geocode: \(error_)" )
            }

            var closestSearchAnnotation: MKAnnotation?
            if let placemarks_ = placemarks
            where placemarks_.count > 0 {
                var closest = CLLocationDistance.infinity
                for placemark: CLPlacemark in placemarks_ {
                    if let placemarkLocation_ = placemark.location, userLocation_ = self.mapView.userLocation.location {
                        let distance = placemarkLocation_.distanceFromLocation( userLocation_ )
                        if distance < closest {
                            closest = distance
                            closestSearchAnnotation = MKPlacemark( placemark: placemark )
                        }
                    }
                }
            }
            self.mapSearchAnnotation = closestSearchAnnotation

            self.activityView.stopAnimating()
        } )
    }

    func searchBarBookmarkButtonClicked(searchBar: UISearchBar) {
        performSegueWithIdentifier( "bookmarks", sender: searchBar )
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

    @IBAction func didTapClear(sender: AnyObject) {
        route = nil

        self.mapView.removeAnnotations( locationAnnotations.array as! [MKAnnotation] )
        locationAnnotations.removeAllObjects()

        mapSearchAnnotation = nil
        mapRouteOverlay = nil

        buildLocationsRoute()
    }

    @IBAction func didTapReload(sender: AnyObject) {
        buildLocationsRoute()
    }

    /* Private */

    func showAnnotations() {
        var annotations: [MKAnnotation] = [ mapView.userLocation ]
        if let mapSearchAnnotation_ = self.mapSearchAnnotation {
            annotations.append( mapSearchAnnotation_ )
        }
        annotations.appendContentsOf( self.locationAnnotations.array as! [MKAnnotation] )
        mapView.showAnnotations( annotations, animated: true )
    }

    func createAddRouteLocationButton(annotation: MKAnnotation) -> UIButton {
        let button = UIButton( type: .ContactAdd )

        button.on( .TouchUpInside, {
            if self.locationAnnotations.containsObject( annotation ) {
                return
            }

            self.locationAnnotations.addObject( annotation )
            self.rebuildRouteLocationsStackView();
            self.showAnnotations()

            if self.locationAnnotations.count == 2 {
                self.buildLocationsRoute();
            }
        } )

        return button
    }

    func rebuildRouteLocationsStackView() {
        for locationButton in [ UIView ]( routeLocationsStackView.arrangedSubviews ) {
            routeLocationsStackView.removeArrangedSubview( locationButton )
            locationButton.removeFromSuperview()
        }
        for locationAnnotation in locationAnnotations {
            routeLocationsStackView.addArrangedSubview( createRouteLocationButton( locationAnnotation as! MKAnnotation ) )
        }
        headerStackMarginConstraint.active = locationAnnotations.count > 0
    }

    func createRouteLocationButton(annotation: MKAnnotation) -> UIButton {
        let button = UIButton( type: .System )

        button.setTitle( annotation.title ?? "Pin", forState: .Normal )
        button.backgroundColor = UIColor.lightTextColor()
        button.layer.cornerRadius = 4
        button.on( .TouchUpInside, {
            self.locationAnnotations.removeObject( annotation )
            self.rebuildRouteLocationsStackView();
            self.showAnnotations()
        } );

        return button
    }

    func buildLocationsRoute() {
        mapRouteOverlay = nil

        if self.locationAnnotations.count < 2 {
            showAnnotations()
            return
        }

        let origin      = self.locationAnnotations.firstObject as! MKAnnotation
        let destination = self.locationAnnotations.lastObject as! MKAnnotation
        Alamofire.request( .GET, "http://planibus.sto.ca/hastinfowebmobile/TravelPlansResults.aspx", parameters: [
                "origin": "external_geolocation_name=origin;external_geolocation_latitude_coordinate=\(origin.coordinate.latitude);external_geolocation_longitude_coordinate=\(origin.coordinate.longitude)",
                "destination": "external_geolocation_name=destination;external_geolocation_latitude_coordinate=\(destination.coordinate.latitude);external_geolocation_longitude_coordinate=\(destination.coordinate.longitude)",
                "flexible": "true"/*,
                "date": "20151018",
                "hour": "1050",
                "timeType": "SpecifiedArrivalTime"*/
        ] ).responseString {
            (response: Response) in
            print( "STO URL:\n\(response.request?.URL)" )
            if !response.result.isSuccess {
                print( "ERROR: STO Error Response:\n\(response.result.error)" )
                return
            }

            if let result_ = response.result.value {
                let html  = HTMLDocument( string: result_ )
                let error = html.firstNodeMatchingSelector( "#ErrorMessageSpan" )
                if let error_ = error {
                    print( "ERROR: STO Error Message:\n\(error_.innerHTML)" )
                }

                var steps   = [ RouteStep ]()
                let results = html.firstNodeMatchingSelector( "#TravelPlansResultsMainPage" )
                if let results_ = results {
                    for result in results_.childElementNodes as! [HTMLElement]
                    where !(result.attributes["id"] as? String ?? "").commonPrefixWithString( "TVP0STEP", options: [] ).isEmpty {
                        var stepMode: RouteStepMode?
                        if let routeStepModeElement = result.firstNodeMatchingSelector( "*[data-role=content]>div[class~=StepImage]" ) {
                            if routeStepModeElement.hasClass( "BusImage" ) {
                                stepMode = .Bus
                            }
                            else if routeStepModeElement.hasClass( "WalkImage" ) {
                                stepMode = .Walk
                            }
                        }

                        let stepTiming      = result.firstNodeMatchingSelector( "*[data-role=content]>span:nth-child(1)" )?.innerHTML
                        let stepModeContext = result.firstNodeMatchingSelector( "*[data-role=content]>span:nth-child(3)" )?.innerHTML
                        let stepExplanation = result.firstNodeMatchingSelector( "*[data-role=content]>p" )?.innerHTML

                        if let stepMode_ = stepMode, stepTiming_ = stepTiming, stepExplanation_ = stepExplanation {
                            steps.append( RouteStep(
                            timing: stepTiming_,
                                    mode: stepMode_, modeContext: stepModeContext,
                                    explanation: stepExplanation_ ) )
                        }
                        else {
                            print( "ERROR: Couldn't parse STO Step:\n\(result.serializedFragment)" )
                        }
                    }
                }
                self.route = Route( steps: steps )
                print( "STO Route:\n\(self.route)" )

                NSOperationQueue.mainQueue().addOperationWithBlock( {
                    var locations = [ origin.coordinate, destination.coordinate ]
                    self.mapRouteOverlay = MKPolyline( coordinates: &locations, count: locations.count )
                    self.showAnnotations()
                } )
            }
        }
    }

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

