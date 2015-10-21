//
// Created by Maarten Billemont on 2015-10-15.
// Copyright (c) 2015 Maarten Billemont. All rights reserved.
//

import UIKit

extension UIControl {

    private class EventHandler {
        let callback: (UIControl, UIEvent) -> Void
        let oneshot:  Bool

        init(_ callback: (UIControl, UIEvent) -> Void, oneshot: Bool) {
            self.callback = callback
            self.oneshot = oneshot
        }

        @objc func invoke(sender: UIControl, event: UIEvent) {
            if oneshot {
                sender.off( unsafeAddressOf( self ) )
            }

            callback( sender, event )
        }
    }

    typealias EventHandlerId = UnsafePointer<Void>

    func on<T:UIControl>(events: UIControlEvents, _ callback: (T, UIEvent) -> Void) -> EventHandlerId {
        assert( self.isKindOfClass( T ), "The handler must receive \(NSStringFromClass( self.dynamicType )) or UIControl" )
        return self.on( events, EventHandler( { callback( $0 as! T, $1 ) }, oneshot: false ) )
    }

    func once<T:UIControl>(events: UIControlEvents, _ callback: (T, UIEvent) -> Void) -> EventHandlerId {
        assert( self.isKindOfClass( T ), "The handler must receive \(NSStringFromClass( self.dynamicType )) or UIControl" )
        return self.on( events, EventHandler( { callback( $0 as! T, $1 ) }, oneshot: true ) )
    }

    func on(events: UIControlEvents, _ callback: () -> Void) -> EventHandlerId {
        return self.on( events, EventHandler( { _, _ in callback() }, oneshot: false ) )
    }

    func once(events: UIControlEvents, _ callback: () -> Void) -> EventHandlerId {
        return self.on( events, EventHandler( { _, _ in callback() }, oneshot: true ) )
    }

    private func on(events: UIControlEvents, _ handler: EventHandler) -> EventHandlerId {
        let ptr: UnsafePointer<Void> = unsafeAddressOf( handler )
        self.addTarget( handler, action: "invoke:event:", forControlEvents: events )
        objc_setAssociatedObject( self, ptr, handler, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC )
        return ptr
    }

    func off(identifier: EventHandlerId) {
        if let handler = objc_getAssociatedObject( self, identifier ) as? EventHandler {
            self.removeTarget( handler, action: nil, forControlEvents: .AllEvents )
            objc_setAssociatedObject( self, identifier, nil, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC )
        }
    }
}
