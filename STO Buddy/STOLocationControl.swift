//
// Created by Maarten Billemont on 2015-12-09.
// Copyright (c) 2015 Maarten Billemont. All rights reserved.
//

import UIKit

class STOLocationControl: UISegmentedControl {
    init(handler: (control:STOLocationControl, segment:LocationControlSegment) -> ()) {
        super.init( items: iterateEnum( LocationControlSegment ).map( { $0.title } ) )

        on( .ValueChanged, {
            if let segment = iterateEnum( LocationControlSegment )[self.selectedSegmentIndex] {
                handler( control: self, segment: segment )
            }
            else {
                preconditionFailure( "Unsupported segment: \(self.selectedSegmentIndex)" )
            }
        } )
    }

    override init(frame: CGRect) {
        super.init( frame: frame )
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError( "init(coder:) has not been implemented" )
    }

    func select(segment: LocationControlSegment?) {
        if let segment_ = segment, index = [ LocationControlSegment ]( iterateEnum( LocationControlSegment ) ).indexOf( segment_ ) {
            selectedSegmentIndex = index
        }
        else {
            selectedSegmentIndex = -1
        }
    }
}

enum LocationControlSegment {
    case Source
    case Destination

    var title: String {
        switch self {
            case .Source:
                return "↱"
            case .Destination:
                return "↴"
        }
    }
}
