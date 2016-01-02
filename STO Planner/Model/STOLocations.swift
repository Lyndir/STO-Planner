//
// Created by Maarten Billemont on 2015-10-23.
// Copyright (c) 2015 Maarten Billemont. All rights reserved.
//

import Foundation
import MapKit

@objc public protocol STOLocationsObserver: class {
    func locationsChanged(locations: STOLocations, byLocation location: STOLocation)

    func locationsCleared(locations: STOLocations)
}

public class STOLocations: NSObject, SequenceType {
    public static var observers = Observers<STOLocationsObserver>()
    public static var recent    = STOLocations( key: "locations.recent" )
    public static var starred   = STOLocations( key: "locations.starred" )

    let key:           String
    var locationDicts: [[String:NSObject]]

    private init(key: String) {
        self.key = key
        self.locationDicts = NSUserDefaults.standardUserDefaults().arrayForKey( key ) as? [[String:NSObject]]
        ?? [ [ String: NSObject ] ]()
    }

    public func generate() -> AnyGenerator<STOLocation> {
        var stateGenerator = locationDicts.generate()
        return anyGenerator( {
            while let locationDict = stateGenerator.next() {
                if self === STOLocations.recent && STOLocations.starred.locationDicts.contains( {
                    return locationDict == $0
                } ) {
                    continue
                }

                return STOLocation( dict: locationDict )
            }

            return nil
        } )
    }

    public var count: Int {
        return locationDicts.count
    }

    public subscript(index: Int) -> STOLocation? {
        return STOLocation( dict: locationDicts[index] )
    }

    func insert(location: STOLocation) {
        locationDicts = locationDicts.filter( { !location.matchesDict( $0 ) } )
        locationDicts.insert( location.toDict(), atIndex: 0 )
        NSUserDefaults.standardUserDefaults().setObject( locationDicts, forKey: key )

        STOLocations.observers.fire {
            $0.locationsChanged( self, byLocation: location )
        }
    }

    func remove(location: STOLocation) {
        let oldCount = locationDicts.count
        locationDicts = locationDicts.filter( { !location.matchesDict( $0 ) } )

        if locationDicts.count < oldCount {
            NSUserDefaults.standardUserDefaults().setObject( locationDicts, forKey: key )

            STOLocations.observers.fire {
                $0.locationsChanged( self, byLocation: location )
            }
        }
    }

    func toggle(location: STOLocation) {
        let locationDictsCount = locationDicts.count
        locationDicts = locationDicts.filter( { !location.matchesDict( $0 ) } )
        if locationDictsCount == locationDicts.count {
            locationDicts.append( location.toDict() )
        }
        NSUserDefaults.standardUserDefaults().setObject( locationDicts, forKey: key )

        STOLocations.observers.fire {
            $0.locationsChanged( self, byLocation: location )
        }
    }

    func contains(location: STOLocation) -> Bool {
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

        STOLocations.observers.fire {
            $0.locationsCleared( self )
        }
    }
}

public class STOLocation: NSObject {
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
        if let myLocation = placemark.location, objLocation = (obj as? STOLocation)?.placemark.location {
            return myLocation.coordinate.longitude == objLocation.coordinate.longitude &&
                   myLocation.coordinate.latitude == objLocation.coordinate.latitude
        }

        return false
    }

    public override var description: String {
        return "{Location: \(placemark)}"
    }
}

@objc public protocol STOLocationMarkObserver {
    func locationChangedForMark(mark: STOLocationMark, toLocation location: STOLocation?)
}

@objc public enum STOLocationMark: Int {
    public static let allValues: [STOLocationMark] = [ .Home, .Work, .Play ]
    public static var observers                    = Observers<STOLocationMarkObserver>()

    case Home
    case Work
    case Play

    var name:  String {
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

    func setLocation(location: STOLocation) {
        for mark in STOLocationMark.allValues {
            if mark == self {
                NSUserDefaults.standardUserDefaults().setObject( location.toDict(), forKey: "locationMarks.\(mark.name)" )
                STOLocationMark.observers.fire {
                    $0.locationChangedForMark( mark, toLocation: location )
                }
            }
            else if mark.matchesLocation( location ) {
                NSUserDefaults.standardUserDefaults().setObject( nil, forKey: "locationMarks.\(mark.name)" )
                STOLocationMark.observers.fire {
                    $0.locationChangedForMark( mark, toLocation: nil )
                }
            }
        }
    }

    func getLocation() -> STOLocation? {
        if let locationDict = NSUserDefaults.standardUserDefaults().objectForKey( "locationMarks.\(self.name)" ) as? [String:NSObject] {
            return STOLocation( dict: locationDict )
        }

        return nil
    }

    func matchesLocation(location: STOLocation) -> Bool {
        if let locationDict = NSUserDefaults.standardUserDefaults().objectForKey( "locationMarks.\(self.name)" ) as? [String:NSObject] {
            return location.matchesDict( locationDict )
        }

        return false
    }
}
