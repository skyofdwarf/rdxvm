//
//  Driving.swift
//  Reduxift
//
//  Created by YEONGJUNG KIM on 2022/01/14.
//

import Foundation
import RxSwift
import RxRelay
import RxCocoa

/// Add this attribute to drive and accept a new value of reference type state property.
/// In reducer, you should use this attribute to update the property with a new value.
///
/// ```
/// in reducer
/// state.prop = `new-value`
/// ```
///
/// Conforms `SharedSequenceConvertibleType` to drive this attribute directly from the outside.
///
/// ```
/// vm.state.$props.drive(to: ...)
/// ```
@propertyWrapper
struct Driving<Element> {
    var wrappedValue: Element {
        get {
            relay.value
        }
        set {
            relay.accept(newValue)
        }
    }
    
    var projectedValue: Self { self }
    fileprivate let relay: BehaviorRelay<Element>
    
    init(wrappedValue: Element) {
        self.relay = BehaviorRelay<Element>(value: wrappedValue)
    }
}

protocol Driverable {
    associatedtype Element
    func asDriver() -> Driver<Element>
}

extension Driving: Driverable {
    func asDriver() -> Driver<Element> {
        relay.asDriver()
    }
}

extension Driving: SharedSequenceConvertibleType {
    func asSharedSequence() -> SharedSequence<DriverSharingStrategy, Element> {
        relay.asDriver()
    }
}

