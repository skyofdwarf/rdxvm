//
//  Stated.swift
//  RDXVM
//
//  Created by YEONGJUNG KIM on 2022/10/24.
//

import RxSwift
import RxRelay
import RxCocoa

/// Stated is a wrapper to drive new state and get current state.
///
/// You can get current state and use it normal way.
/// ```
/// struct State {
///     let foo = 0
/// }
///
/// print(vm.state)
/// print(vm.state.foo)
/// ```
///
/// You can also drive a state.
/// ```
/// struct State {
///     let foo = 0
/// }
/// vm.state
///     .drive(onNext: { state in
///         print(state.foo)
///     })
/// ```
///
/// If state has @Drived property, you can drive it directly.
/// ```
/// struct State {
///     var foo = 0
///     @Drived var bar = 1
/// }
/// vm.state.$bar
///     .drive(onNext: { bar in
///         print(bar)
///     })
/// ```
@propertyWrapper
public struct Stated<Element> {
    public var wrappedValue: Element {
        get {
            relay.value
        }
        set {
            relay.accept(newValue)
        }
    }
    
    public var projectedValue: Self { self }
    internal let relay: BehaviorRelay<Element>
    
    public init(wrappedValue: Element) {
        self.relay = BehaviorRelay<Element>(value: wrappedValue)
    }
    
    internal func accept(_ element: Element) {
        relay.accept(element)
    }
}

extension Stated: SharedSequenceConvertibleType {
    public func asSharedSequence() -> SharedSequence<DriverSharingStrategy, Element> {
        relay.asDriver()
    }
}
