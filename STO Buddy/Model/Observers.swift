//
// Created by Maarten Billemont on 2015-12-07.
// Copyright (c) 2015 Maarten Billemont. All rights reserved.
//

import Foundation

public protocol ObserverX : class {
    
}

public class Observers<Observer> {
    private var observers = [ PearlWeakReference ]()

    public func addObserver(observer: Observer) {
        observers = observers.filter( { return $0.object != nil } )
        observers.append( PearlWeakReference( object: observer as! AnyObject ) )
    }

    public func fireObservers(trigger: (Observer) -> ()) {
        for observer in observers {
            if let observerObject = observer.object as? Observer {
                trigger( observerObject )
            }
        }
    }
}
