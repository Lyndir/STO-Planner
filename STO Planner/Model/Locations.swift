//
// Created by Maarten Billemont on 2015-10-23.
// Copyright (c) 2015 Maarten Billemont. All rights reserved.
//

import Foundation
import MapKit

@objc public protocol LocationsObserver: class {
    func locationsChanged(locations: Locations, byLocation location: Location)

    func locationsCleared(locations: Locations)
}

public class Locations: NSObject, SequenceType {
    public static var observers = Observers<LocationsObserver>()
    public static var recent    = Locations( key: "locations.recent" )
    public static var starred   = Locations( key: "locations.starred" )

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
            while let locationDict = stateGenerator.next() {
                if self === Locations.recent && Locations.starred.locationDicts.contains( {
                    return locationDict == $0
                } ) {
                    continue
                }

                return Location( dict: locationDict )
            }

            return nil
        } )
    }

    public var count: Int {
        return locationDicts.count
    }

    public subscript(index: Int) -> Location? {
        return Location( dict: locationDicts[index] )
    }

    func insert(location: Location) {
        locationDicts = locationDicts.filter( { !location.matchesDict( $0 ) } )
        locationDicts.append( location.toDict() )
        NSUserDefaults.standardUserDefaults().setObject( locationDicts, forKey: key )

        Locations.observers.fire {
            $0.locationsChanged( self, byLocation: location )
        }
    }

    func remove(location: Location) {
        let oldCount = locationDicts.count
        locationDicts = locationDicts.filter( { !location.matchesDict( $0 ) } )

        if locationDicts.count < oldCount {
            NSUserDefaults.standardUserDefaults().setObject( locationDicts, forKey: key )

            Locations.observers.fire {
                $0.locationsChanged( self, byLocation: location )
            }
        }
    }

    func toggle(location: Location) {
        let locationDictsCount = locationDicts.count
        locationDicts = locationDicts.filter( { !location.matchesDict( $0 ) } )
        if locationDictsCount == locationDicts.count {
            locationDicts.append( location.toDict() )
        }
        NSUserDefaults.standardUserDefaults().setObject( locationDicts, forKey: key )

        Locations.observers.fire {
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

        Locations.observers.fire {
            $0.locationsCleared( self )
        }
    }
}

public class Location: NSObject {
    let placemark: STOPlacemark

    init(placemark: STOPlacemark) {
        self.placemark = placemark
    }

    init(dict: [String:NSObject]) {
        self.placemark = STOPlacemark( coordinate: CLLocationCoordinate2D( latitude: (dict["coordinate.latitude"] as! CLLocationDegrees),
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

    public override var description: String {
        return "{Location: \(placemark)}"
    }
}

@objc public protocol LocationMarkObserver {
    func locationChangedForMark(mark: LocationMark, toLocation location: Location?)
}

@objc public enum LocationMark: Int {
    public static var observers = Observers<LocationMarkObserver>()

    case Home
    case Work
    case Play

    var name: String {
        switch self {
        case .Home:
            return "home"
        case .Work:
            return "work"
        case .Play:
            return "play"
        }
    }
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
        for mark in iterateEnum( LocationMark ) {
            if mark == self {
                NSUserDefaults.standardUserDefaults().setObject( location.toDict(), forKey: "locationMarks.\(mark.name)" )
                LocationMark.observers.fire {
                    $0.locationChangedForMark( mark, toLocation: location )
                }
            } else if mark.matchesLocation( location ) {
                NSUserDefaults.standardUserDefaults().setObject( nil, forKey: "locationMarks.\(mark.name)" )
                LocationMark.observers.fire {
                    $0.locationChangedForMark( mark, toLocation: nil )
                }
            }
        }
    }

    func getLocation() -> Location? {
        if let locationDict = NSUserDefaults.standardUserDefaults().objectForKey( "locationMarks.\(self.name)" ) as? [String:NSObject] {
            return Location( dict: locationDict )
        }

        return nil
    }

    func matchesLocation(location: Location) -> Bool {
        if let locationDict = NSUserDefaults.standardUserDefaults().objectForKey( "locationMarks.\(self.name)" ) as? [String:NSObject] {
            return location.matchesDict( locationDict )
        }

        return false
    }
}
