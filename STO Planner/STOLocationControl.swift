//
// Created by Maarten Billemont on 2015-12-09.
// Copyright (c) 2015 Maarten Billemont. All rights reserved.
//

import UIKit

protocol STOLocationControlSegmentResolver {
    func locationControl(control: STOLocationControl, activeSegmentForPlacemark placemark: STOPlacemark) -> STOLocationControlSegment?
}

protocol STOLocationControlSegmentHandler {
    func locationControl(control: STOLocationControl, didSelectSegment segment: STOLocationControlSegment, forPlacemark placemark: STOPlacemark)
}

class STOLocationControl: UISegmentedControl {
    var placemarkResolver: STOPlacemarkResolver!
    var segmentResolver:   STOLocationControlSegmentResolver!

    init(placemarkResolver: STOPlacemarkResolver, segmentResolver: STOLocationControlSegmentResolver, handler: STOLocationControlSegmentHandler) {
        super.init( items: STOLocationControlSegment.allValues.map( { _ in " " } ) )

        self.placemarkResolver = placemarkResolver
        self.segmentResolver = segmentResolver

        on( .ValueChanged, {
            if let selectedSegment_ = self.selectedSegment {
                self.placemarkResolver.resolvePlacemark(
                {
                    handler.locationControl( self, didSelectSegment: selectedSegment_, forPlacemark: $0 )
                    self.selectActiveSegmentForPlacemark( $0 )
                }, placemarkResolutionFailed: {
                    error in
                    self.selectActiveSegmentForPlacemark( nil )
                } )
            }
        } )
    }

    override init(frame: CGRect) {
        super.init( frame: frame )
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError( "init(coder:) has not been implemented" )
    }

    var selectedSegment: STOLocationControlSegment? {
        return STOLocationControlSegment( rawValue: self.selectedSegmentIndex )
    }

    private func selectActiveSegmentForPlacemark(placemark: STOPlacemark?) {
        if let placemark_ = placemark, segment_ = segmentResolver.locationControl( self, activeSegmentForPlacemark: placemark_ ) {
            selectedSegmentIndex = segment_.rawValue
        }
        else {
            selectedSegmentIndex = -1
        }

        for var segment in STOLocationControlSegment.allValues {
            switch segment {
                case .Starred:
                    var starred = false
                    if let placemark_ = placemark {
                        starred = STOLocations.starred.contains( STOLocation( placemark: placemark_ ) )
                    }

                    setTitle( starred ? "★": "☆︎", forSegmentAtIndex: segment.rawValue )
                case .Source:
                    setTitle( "↱", forSegmentAtIndex: segment.rawValue )
                case .Destination:
                    setTitle( "↴", forSegmentAtIndex: segment.rawValue )
            }
        }
    }

    func selectActiveSegment() {
        placemarkResolver.resolvePlacemark( { self.selectActiveSegmentForPlacemark( $0 ) },
                                            placemarkResolutionFailed: { _ in self.selectActiveSegmentForPlacemark( nil ) } )
    }
}

public enum STOLocationControlSegment: Int {
    public static let allValues: [STOLocationControlSegment] = [ .Starred, .Source, .Destination ]

    case Starred
    case Source
    case Destination
}
