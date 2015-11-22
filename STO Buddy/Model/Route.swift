//
// Created by Maarten Billemont on 2015-10-17.
// Copyright (c) 2015 Maarten Billemont. All rights reserved.
//

import Foundation

class Route: CustomStringConvertible {
    let title: String
    let steps: Array<RouteStep>

    init(title: String, steps: Array<RouteStep>) {
        self.title = title
        self.steps = steps
    }

    var description: String {
        var route: String = "{Route:"
        for step in steps {
            route.appendContentsOf( "\n\(step)" )
        }
        route.append( "}" as Character )

        return route
    }
}

class RouteStep: CustomStringConvertible {
    let timing:      String
    let mode:        RouteStepMode
    let modeContext: String?
    let explanation: String

    init(timing: String, mode: RouteStepMode, modeContext: String?, explanation: String) {
        self.timing = timing
        self.mode = mode
        self.modeContext = modeContext
        self.explanation = explanation
    }

    var shortExplanation: String {
        return mode.withContext( modeContext )
    }

    var description: String {
        return "{Step: \(shortExplanation) at \(timing) [ \(explanation) ]}"
    }
}

enum RouteStepMode: Int {
    case Walk
    case Bus

    func withContext(context: String?) -> String {
        if let context_ = context {
            return "\(self) \(context_)"
        }

        return String( self )
    }
}
