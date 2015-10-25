//
// Created by Maarten Billemont on 2015-10-23.
// Copyright (c) 2015 Maarten Billemont. All rights reserved.
//

import Foundation
import CoreLocation

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
            return locationState == nil ? nil: Location( locationState! )
        } )
    }

    public var count: Int {
        return state.count
    }

    public subscript(index: Int) -> Location {
        return Location( state[index] )
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
    let name:      String
    let latitude:  CLLocationDegrees
    let longitude: CLLocationDegrees

    init(name: String, latitude: CLLocationDegrees, longitude: CLLocationDegrees) {
        print( "creating Location (name: \(name), lat: \(latitude), long: \(longitude))" )
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
    }

    init(_ dict: [String:AnyObject]) {
        self.name = dict["name"] as! String
        self.latitude = dict["latitude"] as! Double
        self.longitude = dict["longitude"] as! Double
    }

    func toDict() -> [String:AnyObject] {
        return [ "name": name,
                 "latitude": latitude,
                 "longitude": longitude ]
    }

    func matchesDict(dict: [String:AnyObject]) -> Bool {
        if let name_ = dict["name"] as? String {
            return name_ != self.name
        }

        return false
    }
}
