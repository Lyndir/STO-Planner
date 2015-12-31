//
//  Language.swift
//  STO Planner
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

extension GeneratorType {
    public func at(index: Int) -> Self.Element? {
        var lastValue: Self.Element?, advancingSelf = self

        for (var current = index; current >= 0; --current) {
            lastValue = advancingSelf.next()
            if lastValue == nil {
                break
            }
        }

        return lastValue
    }
}

extension Indexable {
    func at(index: Index) -> Self._Element? {
        let fromStart = startIndex.distanceTo( index )
        if fromStart < 0 {
            return nil
        }
        if fromStart >= startIndex.distanceTo( endIndex ) {
            return nil
        }

        return self[index]
    }
}

struct WeakReference<T> {
    private weak var _value: AnyObject?
}

extension WeakReference where T: AnyObject {
    init(_ value: T) {
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
