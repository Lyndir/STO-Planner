//
// Created by Maarten Billemont on 2015-10-23.
// Copyright (c) 2015 Maarten Billemont. All rights reserved.
//

import Foundation
import MapKit

public class Locations: SequenceType {
    let key:   String
    var state: [Dictionary<String, AnyObject>]

    public class func recent() -> Locations {
        return Locations( key: "locations.recent" )
    }

    public class func starred() -> Locations {
        return Locations( key: "locations.starred" )
    }

    private init(key: String) {
        self.key = key
        self.state = NSUserDefaults.standardUserDefaults().arrayForKey( key ) as? [[String:AnyObject]]
        ?? [ [ String: AnyObject ] ]()
    }

    public func generate() -> AnyGenerator<Location> {
        var stateGenerator = state.generate()
        return anyGenerator( {
            let locationState = stateGenerator.next()
            return locationState == nil ? nil: Location( dict: locationState! )
        } )
    }

    public var count: Int {
        return state.count
    }

    public subscript(index: Int) -> Location {
        return Location( dict: state[index] )
    }

    func add(location: Location) {
        state = state.filter( { location.matchesDict( $0 ) } )
        state.append( location.toDict() )
        NSUserDefaults.standardUserDefaults().setObject( state, forKey: key )
    }

    func clear() {
        state = [ [ String: AnyObject ] ]()
        NSUserDefaults.standardUserDefaults().setObject( state, forKey: key )
    }
}

public class Location {
    let placemark: MKPlacemark

    init(placemark: MKPlacemark) {
        self.placemark = placemark
    }

    init(dict: [String:AnyObject]) {
        self.placemark = MKPlacemark( coordinate: CLLocationCoordinate2D( latitude: dict["coordinate.latitude"]!.doubleValue!,
                                                                          longitude: dict["coordinate.longitude"]!.doubleValue! ),
                                      addressDictionary: dict["addressDictionary"] as! [String:AnyObject]? )
    }

    func toDict() -> [String:AnyObject] {
        return [ "coordinate.latitude": placemark.coordinate.latitude,
                 "coordinate.longitude": placemark.coordinate.longitude,
                 "addressDictionary": placemark.addressDictionary! ]
    }

    func matchesDict(dict: [String:AnyObject]) -> Bool {
        if let latitude_ = dict["coordinate.latitude"] as? CLLocationDegrees,
        longitude_ = dict["coordinate.longitude"] as? CLLocationDegrees {
            return latitude_ == self.placemark.coordinate.latitude && longitude_ == self.placemark.coordinate.longitude
        }

        return false
    }
}
