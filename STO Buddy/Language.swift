//
//  Language.swift
//  STO Buddy
//
//  Created by Maarten Billemont on 2015-10-15.
//  Copyright © 2015 Maarten Billemont. All rights reserved.
//

import Foundation

infix operator % { associativity left
    precedence 0 }

func %(left: String, right: [CVarArgType]) -> String {
    return String( format: left, arguments: right )
}

func iterateEnum<T:Hashable>(_: T.Type) -> AnyGenerator<T> {
    var i = 0
    return anyGenerator {
        let next = withUnsafePointer( &i ) {
            UnsafePointer<T>( $0 ).memory
        }
        return next.hashValue == i++ ? next: nil
    }
}

struct WeakReference<T> {
    private weak var _value: AnyObject?
}

extension WeakReference where T:AnyObject {
    init(_ value : T) {
        self.value = value
    }
    
    var value: T? {
        get {
            return _value as! T?
        }
        set {
            _value = newValue
        }
    }
}
