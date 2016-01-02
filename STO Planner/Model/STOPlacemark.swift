//
// Created by Maarten Billemont on 2015-12-10.
// Copyright (c) 2015 Maarten Billemont. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

class STOPlacemark: MKPlacemark {
    var resolver:    STOPlacemarkResolver?
    var routeLookup: STORouteLookup?

    override init(placemark: CLPlacemark) {
        super.init( placemark: placemark )
    }

    override init(coordinate: CLLocationCoordinate2D, addressDictionary: [String:AnyObject]?) {
        super.init( coordinate: coordinate, addressDictionary: addressDictionary )
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError( "init(coder:) has not been implemented" )
    }

    private var  _title: String?
    override var title:  String? {
        get {
            return _title ?? self.name
        }
        set {
            _title = newValue
        }
    }

    override var subtitle: String? {
        if let firstRoute = routeLookup?.routes.first,
        firstStep = firstRoute.steps.filter( { $0.mode == .Bus } ).first ?? firstRoute.steps.first {
            return "\(firstStep.shortExplanation): \(firstRoute.title)"
        }

        return nil
    }
}
