//
// Created by Maarten Billemont on 2015-09-24.
// Copyright (c) 2015 Maarten Billemont. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit
import Alamofire
import HTMLReader

class MapViewController: UIViewController, UIGestureRecognizerDelegate, UISearchBarDelegate, CLLocationManagerDelegate, MKMapViewDelegate, UIScrollViewDelegate {
    let geoCoder        = CLGeocoder()
    let locationManager = CLLocationManager()

    lazy var mapLocationPlacemarkResolver: STOPlacemarkLocationResolver
    = STOPlacemarkLocationResolver( geoCoder: self.geoCoder, locationSupplier: {
        self.mapView.userLocation.location
    } )

    var searchPlacemark: MKPlacemark? {
        willSet {
            if let searchPlacemark_ = searchPlacemark {
                mapView.removeAnnotation( searchPlacemark_ )
            }
        }
        didSet {
            if let searchPlacemark_ = searchPlacemark {
                mapView.addAnnotation( searchPlacemark_ )
                triggerLocation( Location( placemark: searchPlacemark_ ) )
                showAnnotations()
            }
        }
    }
    var isFlippingSourceAndDestinationPlacemarks = false
    var sourcePlacemark: MKPlacemark? {
        willSet {
            if let sourcePlacemark_ = sourcePlacemark {
                mapView.removeAnnotation( sourcePlacemark_ )
            }
            if let newValue_ = newValue {
                if newValue_ == destinationPlacemark && !isFlippingSourceAndDestinationPlacemarks {
                    isFlippingSourceAndDestinationPlacemarks = true
                    destinationPlacemark = sourcePlacemark
                    isFlippingSourceAndDestinationPlacemarks = false
                }
                else if destinationPlacemark == nil {
                    mapLocationPlacemarkResolver.resolvePlacemark( {
                                                                       (placemark: MKPlacemark) in

                                                                       self.destinationPlacemark = placemark
                                                                   }, placemarkResolutionFailed: {
                    } )
                }
            }
        }
        didSet {
            rebuildRouteLocationsStackView()

            if let sourcePlacemark_ = sourcePlacemark {
                mapView.addAnnotation( sourcePlacemark_ )
                showAnnotations()
            }

            buildLocationsRoute()
        }
    }
    var destinationPlacemark: MKPlacemark? {
        willSet {
            if let destinationPlacemark_ = destinationPlacemark {
                mapView.removeAnnotation( destinationPlacemark_ )
            }
            if let newValue_ = newValue {
                if newValue_ == sourcePlacemark && !isFlippingSourceAndDestinationPlacemarks {
                    isFlippingSourceAndDestinationPlacemarks = true
                    sourcePlacemark = destinationPlacemark
                    isFlippingSourceAndDestinationPlacemarks = false
                }
                else if sourcePlacemark == nil {
                    mapLocationPlacemarkResolver.resolvePlacemark( {
                                                                       (placemark: MKPlacemark) in

                                                                       self.sourcePlacemark = placemark
                                                                   }, placemarkResolutionFailed: {
                    } )
                }
            }
        }
        didSet {
            rebuildRouteLocationsStackView()

            if let destinationPlacemark_ = destinationPlacemark {
                mapView.addAnnotation( destinationPlacemark_ )
                showAnnotations()
            }

            buildLocationsRoute()
        }
    }
    var routeOverlay: MKPolyline? {
        willSet {
            if let routeOverlay_ = routeOverlay {
                mapView.removeOverlay( routeOverlay_ )
            }
        }
        didSet {
            if let routeOverlay_ = routeOverlay {
                mapView.addOverlay( routeOverlay_ )
            }
        }
    }
    var routeLookup: RouteLookup? {
        didSet {
            print( self.routeLookup )
            rightSlideOutViewController.routeLookup = routeLookup

            view.layoutIfNeeded()
            UIView.animateWithDuration( 0.3, animations: {
                if self.routeLookup == nil {
                    self.rightSlideOutConstraint.constant = 0
                }
                else {
                    self.rightSlideOutConstraint.constant = -self.rightSlideOut.bounds.size.width
                }

                self.view.layoutIfNeeded()
            } )

            if let routeLookup_ = self.routeLookup {
                var locations = [ routeLookup_.sourcePlacemark.coordinate,
                                  routeLookup_.destinationPlacemark.coordinate ]
                self.routeOverlay = MKPolyline( coordinates: &locations, count: locations.count )
                self.showAnnotations()
            }
        }
    }
    var travelTime: STOTravelTime = STOTravelTimeLeavingNow() {
        didSet {
            self.view.layoutIfNeeded()
            UIView.animateWithDuration( 0.3, animations: {
                self.travelTimePager.currentPage = self.travelTime.page()
                self.travelTimeNowConstraint.active = !(self.travelTime is STOFutureTravelTime)
                self.view.layoutIfNeeded()
            } )

            if !(travelTimePicker.tracking || travelTimePicker.dragging || travelTimePicker.decelerating) {
                travelTimePicker.setContentOffset(
                CGPointMake( CGFloat( travelTime.page() ) * travelTimePicker.frame.size.width, 0 ),
                animated: true )
            }
            if let arrivingTravelTime = travelTime as? STOTravelTimeArriving {
                arrivingTimeControl.date = arrivingTravelTime.at()
            }
            if let leavingTravelTime = travelTime as? STOTravelTimeLeaving {
                leavingTimeControl.date = leavingTravelTime.at()
            }

            buildLocationsRoute()
        }
    }
    var planibusRequest: Request? {
        willSet {
            planibusRequest?.cancel()
        }
    }

    @IBOutlet var headerBlurView:          UIVisualEffectView!
    @IBOutlet var travelTimeNowConstraint: NSLayoutConstraint!
    @IBOutlet var searchBar:               UISearchBar!
    @IBOutlet var travelTimePicker:        UIScrollView!
    @IBOutlet var travelTimePager:         UIPageControl!
    @IBOutlet var arrivingTimeControl:     UIDatePicker!
    @IBOutlet var leavingTimeControl:      UIDatePicker!
    @IBOutlet var routeLocationsStackView: UIStackView!
    @IBOutlet var activityView:            UIActivityIndicatorView!
    @IBOutlet var mapView:                 MKMapView!
    @IBOutlet var toolBar:                 UIToolbar!

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

        toolBar.items!.insert( MKUserTrackingBarButtonItem( mapView: self.mapView ), atIndex: 0 )

        rightSlideOutConstraint.constant = 0
        rebuildRouteLocationsStackView()

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
            rightSlideOutViewController = (segue.destinationViewController as! UINavigationController).viewControllers.first as! RouteViewController
        }
        if segue.identifier == "bookmarks" {
            (segue.destinationViewController as! STONavigationController).mapViewController = self
        }

        super.prepareForSegue( segue, sender: sender )
    }

    /* MKMapViewDelegate */

    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        if let searchPlacemark_ = searchPlacemark
        where searchPlacemark_ === annotation {
            let identifier                           = "SearchAnnotation"
            var annotationView: MKPinAnnotationView! =
            mapView.dequeueReusableAnnotationViewWithIdentifier( identifier ) as? MKPinAnnotationView
            if annotationView == nil {
                annotationView = MKPinAnnotationView( annotation: searchPlacemark_, reuseIdentifier: identifier )
            }
            else {
                annotationView.annotation = searchPlacemark_
            }

            annotationView.pinTintColor = MKPinAnnotationView.redPinColor()
            annotationView.animatesDrop = true
            addSourceOrDestinationCallout( annotationView,
                                           placemarkResolver: STOPlacemarkValueResolver( placemark: searchPlacemark_ ) )

            return annotationView
        }

        return nil
    }

    func mapView(mapView: MKMapView, rendererForOverlay overlay: MKOverlay) -> MKOverlayRenderer {
        if let routeOverlay_ = self.routeOverlay
        where routeOverlay_ === overlay {
            let renderer = MKPolylineRenderer( polyline: routeOverlay_ )
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
                addSourceOrDestinationCallout( annotationView, placemarkResolver: mapLocationPlacemarkResolver )
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
                print( "ERROR: Geocode: \(error_.fullDescription())" )
            }

            var closestSearchAnnotation: MKPlacemark?
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
            self.searchPlacemark = closestSearchAnnotation

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

    /* UIScrollViewDelegate */

    func scrollViewDidScroll(scrollView: UIScrollView) {
        let scrollPage = Int( scrollView.contentOffset.x / scrollView.frame.size.width + 0.5 )
        if scrollView == self.travelTimePicker {
            if travelTime.page() != scrollPage {
                switch scrollPage {
                    case 0:
                        travelTime = STOTravelTimeLeavingNow()
                    case 1:
                        travelTime = STOTravelTimeArriving( time: self.arrivingTimeControl.date )
                    case 2:
                        travelTime = STOTravelTimeLeaving( time: self.leavingTimeControl.date )
                    default:
                        preconditionFailure( "Unexpected travel time page: \(scrollPage)" )
                }
            }
        }
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
        routeLookup = nil
        searchPlacemark = nil
        sourcePlacemark = nil
        destinationPlacemark = nil
        routeOverlay = nil
    }

    @IBAction func didTapReload(sender: AnyObject) {
        buildLocationsRoute()
    }

    @IBAction func didTapMark(barButtonItem: UIBarButtonItem) {
        if let location = LocationMark( rawValue: barButtonItem.tag )?.getLocation() {
            triggerLocation( location )
        }
    }

    /* Private */

    func showAnnotations() {
        var annotations: [MKAnnotation] = [ mapView.userLocation ]
        if let seachPlacemark_ = self.searchPlacemark {
            annotations.append( seachPlacemark_ )
        }
        if let sourcePlacemark_ = self.sourcePlacemark {
            annotations.append( sourcePlacemark_ )
        }
        if let destinationPlacemark_ = self.destinationPlacemark {
            annotations.append( destinationPlacemark_ )
        }

        let mapRect = mapView.visibleMapRect
        mapView.showAnnotations( annotations, animated: false )
        let annotationsRect = mapView.visibleMapRect
        mapView.setVisibleMapRect( mapRect, animated: false )
        var mapInsets = mapView.occludedInsets()
        mapInsets.right = 0
        mapView.setVisibleMapRect( annotationsRect, edgePadding: mapInsets, animated: true );
    }

    func triggerLocation(location: Location) {
        if destinationPlacemark == nil {
            destinationPlacemark = location.placemark
        }
        else if sourcePlacemark == nil {
            sourcePlacemark = location.placemark
        }
        else {
            destinationPlacemark = location.placemark
        }

        Locations.recent().add( location )
    }

    func addSourceOrDestinationCallout(annotationView: MKAnnotationView, placemarkResolver: STOPlacemarkResolver) {
        let control = UISegmentedControl( items: [ "↱", "↴" ] )
        control.on( .ValueChanged, {
            placemarkResolver.resolvePlacemark( {
                                                    (placemark: MKPlacemark) in

                                                    switch control.selectedSegmentIndex {
                                                        case 0:
                                                            self.sourcePlacemark = placemark

                                                        case 1:
                                                            self.destinationPlacemark = placemark

                                                        default:
                                                            preconditionFailure( "Unexpected segment for source/destination control: \(control.selectedSegmentIndex)" )
                                                    }

                                                    Locations.recent().add( Location( placemark: placemark ) )
                                                }, placemarkResolutionFailed: {
                control.selectedSegmentIndex = -1
            } )
        } )

        annotationView.rightCalloutAccessoryView = control
        annotationView.canShowCallout = true
    }

    func rebuildRouteLocationsStackView() {
        for locationButton in [ UIView ]( routeLocationsStackView.arrangedSubviews ) {
            routeLocationsStackView.removeArrangedSubview( locationButton )
            locationButton.removeFromSuperview()
        }
        if let sourcePlacemark_ = sourcePlacemark {
            routeLocationsStackView.addArrangedSubview( createRouteLocationButtonWithPlacemark( sourcePlacemark_ ) )
        }
        if let destinationPlacemark_ = destinationPlacemark {
            routeLocationsStackView.addArrangedSubview( createRouteLocationButtonWithPlacemark( destinationPlacemark_ ) )
        }
    }

    func createRouteLocationButtonWithPlacemark(placemark: MKPlacemark) -> UIButton {
        let locationButton = UIButton( type: .System )
        locationButton.backgroundColor = UIColor.lightTextColor()
        locationButton.layer.cornerRadius = 4

        // Title
        var title = placemark.title ?? "Pin"
        if placemark == sourcePlacemark {
            title = "From: \(title)"
        }
        else if placemark == destinationPlacemark {
            title = "To: \(title)"
        }
        locationButton.setTitle( title, forState: .Normal )
        locationButton.titleLabel!.lineBreakMode = .ByTruncatingTail

        // Action
        locationButton.on( .TouchUpInside, {
            if placemark == self.sourcePlacemark {
                self.sourcePlacemark = nil
            }
            else if placemark == self.destinationPlacemark {
                self.destinationPlacemark = nil
            }
        } )

        return locationButton
    }

    func buildLocationsRoute() {
        routeOverlay = nil
        routeLookup = nil

        if let sourcePlacemark_ = sourcePlacemark, destinationPlacemark_ = destinationPlacemark {
            var parameters = [
                    "origin": "external_geolocation_name=origin;external_geolocation_latitude_coordinate=\(sourcePlacemark_.coordinate.latitude);external_geolocation_longitude_coordinate=\(sourcePlacemark_.coordinate.longitude)",
                    "destination": "external_geolocation_name=destination;external_geolocation_latitude_coordinate=\(destinationPlacemark_.coordinate.latitude);external_geolocation_longitude_coordinate=\(destinationPlacemark_.coordinate.longitude)",
                    "flexible": "false"
            ]
            for (key, value) in travelTime.planibusParameters() {
                parameters.updateValue( value, forKey: key )
            }

            planibusRequest = Alamofire.request( .GET, "http://planibus.sto.ca/HastinfoWebMobile/TravelPlansResults.aspx",
                                                 parameters: parameters )
            planibusRequest?.responseString {
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

                    let routeResults = html.firstNodeMatchingSelector( "#TravelPlanLinkListView" )
                    var routeTitles  = [ String ]()
                    var routes       = [ Route ]()
                    if let routeResults_ = routeResults {
                        for result in routeResults_.nodesMatchingSelector( "li>a[data-clientsideurl] p" ) as! [HTMLElement] {
                            routeTitles.append( result.textContent )
                        }
                    }

                    let stepResults = html.firstNodeMatchingSelector( "#TravelPlansResultsMainPage" )
                    if let stepResults_ = stepResults where routeTitles.count > 0 {
                        var routeSteps = [ RouteStep ]()
                        for route in 0 ... (routeTitles.count - 1) {
                            routeSteps.removeAll()

                            for result in stepResults_.childElementNodes as! [HTMLElement]
                            where (result.attributes["id"] as? String ?? "").commonPrefixWithString( "TVP\(route)STEP", options: [] ) == "TVP\(route)STEP" {
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
                                    routeSteps.append( RouteStep(
                                                       timing: stepTiming_,
                                                       mode: stepMode_, modeContext: stepModeContext,
                                                       explanation: stepExplanation_ ) )
                                }
                                else {
                                    print( "ERROR: Couldn't parse STO Step:\n\(result.serializedFragment)" )
                                }
                            }

                            if (routeSteps.count > 0) {
                                routes.append( Route( title: routeTitles[route], steps: routeSteps ) )
                            }
                        }
                    }

                    NSOperationQueue.mainQueue().addOperationWithBlock( {
                        self.routeLookup = RouteLookup( sourcePlacemark: sourcePlacemark_, destinationPlacemark: destinationPlacemark_,
                                                        travelTime: self.travelTime, routes: routes )
                    } )
                }
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

        self.view.layoutIfNeeded()
        UIView.animateWithDuration( gestureState == UIGestureRecognizerState.Changed ? 0: 0.3, animations: {
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

            self.view.layoutIfNeeded()
        } )
    }
}

protocol STOPlacemarkResolver {
    func resolvePlacemark(placemarkResolved: (MKPlacemark) -> (), placemarkResolutionFailed: () -> ())
}

class STOPlacemarkValueResolver: STOPlacemarkResolver {
    let placemark: MKPlacemark

    init(placemark: MKPlacemark) {
        self.placemark = placemark
    }

    func resolvePlacemark(placemarkResolved: (MKPlacemark) -> (), placemarkResolutionFailed: () -> ()) {
        placemarkResolved( placemark )
    }
}

class STOPlacemarkLocationResolver: STOPlacemarkResolver {
    let geoCoder:         CLGeocoder
    let locationSupplier: () -> (CLLocation?)

    init(geoCoder: CLGeocoder, locationSupplier: () -> (CLLocation?)) {
        self.geoCoder = geoCoder
        self.locationSupplier = locationSupplier
    }

    func resolvePlacemark(placemarkResolved: (MKPlacemark) -> (), placemarkResolutionFailed: () -> ()) {
        if let location_ = locationSupplier() {
            geoCoder.reverseGeocodeLocation( location_, completionHandler: {
                (placemarks: [CLPlacemark]?, error: NSError?) in
                if let error_ = error {
                    print( "ERROR: Reverse Geocode: \(error_.fullDescription())" )
                }

                if let firstPlacemark = placemarks?.first {
                    placemarkResolved( MKPlacemark( placemark: firstPlacemark ) )
                }
                else {
                    placemarkResolutionFailed()
                }
            } )
        }
        else {
            placemarkResolutionFailed()
        }
    }
}

// TODO: Can we turn this into an enum instead and turn scrollPage into a type-checked value?

protocol STOTravelTime {
    func page() -> Int

    func planibusParameters() -> Dictionary<String, String>
}

class STOFutureTravelTime: STOTravelTime {
    let dateFormatter = NSDateFormatter(), timeFormatter = NSDateFormatter()
    let time: NSDate

    init(time: NSDate) {
        dateFormatter.dateFormat = "yyyyMMdd"
        timeFormatter.dateFormat = "HHmm"
        self.time = time
    }

    func at() -> NSDate {
        return time
    }

    func page() -> Int {
        preconditionFailure( "Abstract class not fully implemented" );
    }

    func planibusParameters() -> Dictionary<String, String> {
        preconditionFailure( "Abstract class not fully implemented" );
    }
}

class STOTravelTimeLeavingNow: STOTravelTime {
    func page() -> Int {
        return 0
    }

    func planibusParameters() -> Dictionary<String, String> {
        return [:]
    }
}

class STOTravelTimeArriving: STOFutureTravelTime {
    override func page() -> Int {
        return 1
    }

    override func planibusParameters() -> Dictionary<String, String> {
        return [
                "date": dateFormatter.stringFromDate( time ),
                "hour": timeFormatter.stringFromDate( time ),
                "timeType": "SpecifiedArrivalTime"
        ]
    }
}

class STOTravelTimeLeaving: STOFutureTravelTime {
    override func page() -> Int {
        return 2
    }

    override func planibusParameters() -> Dictionary<String, String> {
        return [
                "date": dateFormatter.stringFromDate( time ),
                "hour": timeFormatter.stringFromDate( time ),
                "timeType": "SpecifiedDepartureTime"
        ]
    }
}
