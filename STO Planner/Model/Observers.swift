//
// Created by Maarten Billemont on 2015-12-07.
// Copyright (c) 2015 Maarten Billemont. All rights reserved.
//

import Foundation

public class Observers<O: AnyObject> {
    private var observers = Set<PearlWeakReference>()

    public func add(observer: O) {
        observers.insert( PearlWeakReference( object: observer ) )
    }

    public func fire(trigger: (O) -> ()) {
        for observer in observers {
            if let observerObject = observer.object as? O {
                trigger( observerObject )
            }
        }
    }
}
