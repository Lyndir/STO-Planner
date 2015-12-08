//
// Created by Maarten Billemont on 2015-10-23.
// Copyright (c) 2015 Maarten Billemont. All rights reserved.
//

import Foundation
import MapKit

public protocol LocationsObserver: class {
    func locationsChanged(locations: Locations, byLocation location: Location)

    func locationsCleared(locations: Locations)
}

public class Locations: SequenceType {
    public static var observers = Observers<LocationsObserver>()
    public static var  recent    = Locations( key: "locations.recent" )
    public static var  starred   = Locations( key: "locations.starred" )

    let key:           String
    var locationDicts: [[String:NSObject]]

    private init(key: String) {
        self.key = key
        self.locationDicts = NSUserDefaults.standardUserDefaults().arrayForKey( key ) as? [[String:NSObject]]
        ?? [ [ String: NSObject ] ]()
    }

    public func generate() -> AnyGenerator<Location> {
        var stateGenerator = locationDicts.generate()
        return anyGenerator( {
            if let locationDict = stateGenerator.next() {
                if self === Locations.recent && Locations.starred.locationDicts.contains( {
                    return locationDict == $0
                } ) {
                    return nil
                }

                return Location( dict: locationDict )
            }

            return nil
        } )
    }

    public var count: Int {
        return locationDicts.count
    }

    public subscript(index: Int) -> Location {
        return Location( dict: locationDicts[index] )
    }

    func add(location: Location) {
        locationDicts = locationDicts.filter( { !location.matchesDict( $0 ) } )
        locationDicts.append( location.toDict() )
        NSUserDefaults.standardUserDefaults().setObject( locationDicts, forKey: key )

        Locations.observers.fireObservers {
            $0.locationsChanged( self, byLocation: location )
        }
    }

    func toggle(location: Location) {
        let locationDictsCount = locationDicts.count
        locationDicts = locationDicts.filter( { !location.matchesDict( $0 ) } )
        if locationDictsCount == locationDicts.count {
            locationDicts.append( location.toDict() )
        }
        NSUserDefaults.standardUserDefaults().setObject( locationDicts, forKey: key )

        Locations.observers.fireObservers {
            $0.locationsChanged( self, byLocation: location )
        }
    }

    func contains(location: Location) -> Bool {
        for locationDict in locationDicts {
            if (location.matchesDict( locationDict )) {
                return true;
            }
        }

        return false
    }

    func clear() {
        locationDicts = [ [ String: NSObject ] ]()
        NSUserDefaults.standardUserDefaults().setObject( locationDicts, forKey: key )

        Locations.observers.fireObservers {
            $0.locationsCleared( self )
        }
    }
}

public class Location: NSObject {
    let placemark: MKPlacemark

    init(placemark: MKPlacemark) {
        self.placemark = placemark
    }

    init(dict: [String:NSObject]) {
        self.placemark = MKPlacemark( coordinate: CLLocationCoordinate2D( latitude: (dict["coordinate.latitude"] as! CLLocationDegrees),
                                                                          longitude: (dict["coordinate.longitude"]! as! CLLocationDegrees) ),
                                      addressDictionary: dict["addressDictionary"] as! [String:NSObject]? )
    }

    func toDict() -> [String:NSObject] {
        return [ "coordinate.latitude": placemark.coordinate.latitude,
                 "coordinate.longitude": placemark.coordinate.longitude,
                 "addressDictionary": placemark.addressDictionary! ]
    }

    func matchesDict(dict: [String:NSObject]) -> Bool {
        if let latitude_ = dict["coordinate.latitude"] as? CLLocationDegrees,
        longitude_ = dict["coordinate.longitude"] as? CLLocationDegrees {
            return latitude_ == self.placemark.coordinate.latitude && longitude_ == self.placemark.coordinate.longitude
        }

        return false
    }

    public override var hash: Int {
        if let myLocation = placemark.location {
            return myLocation.coordinate.longitude.hashValue &+ myLocation.coordinate.latitude.hashValue &* 31
        }

        return 0
    }

    public override func isEqual(obj: AnyObject?) -> Bool {
        if let myLocation = placemark.location, objLocation = (obj as? Location)?.placemark.location {
            return myLocation.coordinate.longitude == objLocation.coordinate.longitude &&
                   myLocation.coordinate.latitude == objLocation.coordinate.latitude
        }

        return false
    }
}

public protocol LocationMarkObserver: class {
    func locationChangedForMark(mark: LocationMark, toLocation location: Location)
}

public enum LocationMark: Int {
    public static var observers = Observers<LocationMarkObserver>()

    case Home
    case Work
    case Play

    var title: String {
        switch self {
            case .Home:
                return "🏠"
            case .Work:
                return "🏢"
            case .Play:
                return "🌲"
        }
    }

    func setLocation(location: Location) {
        NSUserDefaults.standardUserDefaults().setObject( location.toDict(), forKey: "locationMarks.\(self)" )

        LocationMark.observers.fireObservers {
            $0.locationChangedForMark( self, toLocation: location )
        }
    }

    func getLocation() -> Location? {
        if let locationDict = NSUserDefaults.standardUserDefaults().objectForKey( "locationMarks.\(self)" ) as? [String:NSObject] {
            return Location( dict: locationDict )
        }

        return nil
    }

    func matchesLocation(location: Location) -> Bool {
        if let locationDict = NSUserDefaults.standardUserDefaults().objectForKey( "locationMarks.\(self)" ) as? [String:NSObject] {
            return location.matchesDict( locationDict )
        }

        return false
    }
}
