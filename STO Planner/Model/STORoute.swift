//
// Created by Maarten Billemont on 2015-10-17.
// Copyright (c) 2015 Maarten Billemont. All rights reserved.
//

import Foundation
import MapKit

class STORouteLookup: CustomStringConvertible {
    let sourcePlacemark:      MKPlacemark
    let destinationPlacemark: MKPlacemark
    let travelTime:           STOTravelTime
    let routes:               Array<STORoute>
    let title:                String

    init(sourcePlacemark: MKPlacemark, destinationPlacemark: MKPlacemark,
         travelTime: STOTravelTime, routes: Array<STORoute>) {
        self.sourcePlacemark = sourcePlacemark
        self.destinationPlacemark = destinationPlacemark
        self.travelTime = travelTime
        self.routes = routes
        self.title = "\(self.sourcePlacemark.thoroughfare) -> \(self.destinationPlacemark.thoroughfare)"
    }

    var description: String {
        var lookup: String = "{RouteLookup[\(title)]:"
        for route in routes {
            lookup.appendContentsOf( "\n\(route)" )
        }
        lookup.append( "}" as Character )

        return lookup
    }
}

class STORoute: CustomStringConvertible {
    let title: String
    let steps: [STORouteStep]

    init(title: String, steps: [STORouteStep]) {
        self.title = title
        self.steps = steps
    }

    var description: String {
        var route: String = "{Route[\(title)]:"
        for step in steps {
            route.appendContentsOf( "\n\(step)" )
        }
        route.append( "}" as Character )

        return route
    }
}

class STORouteStep: CustomStringConvertible {
    let timing:      String
    let mode:        STORouteStepMode
    let modeContext: String?
    let explanation: NSAttributedString

    init(timing: String, mode: STORouteStepMode, modeContext: String?, explanation: NSAttributedString) {
        self.timing = timing
        self.mode = mode
        self.modeContext = modeContext
        self.explanation = explanation
    }

    var shortExplanation: String {
        return mode.descriptionWithContext( modeContext )
    }

    var description: String {
        return "{Step: \(shortExplanation) at \(timing) [ \(explanation) ]}"
    }
}

enum STORouteStepMode: String {
    case Walk = "🚶"
    case Bus = "🚍"

    var thumbnailImage: UIImage {
        return UIImage( named: "\(self)".lowercaseString )!
    }

    var backgroundImage: UIImage {
        return UIImage( named: "\(self)-large".lowercaseString )!
    }

    func descriptionWithContext(context: String?) -> String {
        if let context_ = context {
            return "\(rawValue) \(context_)"
        }

        return rawValue
    }
}
