//
//  StateDriver.swift
//  RDXVM
//
//  Created by YEONGJUNG KIM on 2022/10/25.
//

import RxSwift
import RxRelay
import RxCocoa

/// StateDriver is a wrapper to drive state or properties of the state.
///
/// You have 2 options to get new value of state. You should use one way for consistency.
///
/// 1. drive state to get a new state value.
///     ```
///     struct State {
///         let foo = 0
///         let bar = 1
///     }
///     vm.state
///         .drive(onNext: { state in
///             print(state.foo)
///             print(state.bar)
///         })
///     ```
///
/// 2. drive property of state directly to get a new property value.
///     ```
///     struct State {
///         @Drived var foo = 0
///         @Drived var bar = 1
///     }
///     vm.state.$foo
///         .drive(onNext: { foo in
///             print(foo)
///         })
///     vm.state.$bar
///         .drive(onNext: { bar in
///             print(bar)
///         })
///     ```
///
/// To get current value of the state itself, prefix state with `$`.
/// ```
/// print(vm.$state)
/// ```
///
/// But to get current property value of the state, `$` prefix can be omitted.
/// ```
/// struct State {
///     @Drived var foo = 0
///     let bar = 1
/// }
/// vm.state.foo == vm.$state.foo
/// ```
@dynamicMemberLookup
public struct StateDriver<Element> {
    internal let relay: BehaviorRelay<Element>
    
    public init (state: Element) {
        relay = BehaviorRelay<Element>(value: state)
    }
    
    /// get state property
    public subscript<T>(dynamicMember keyPath: KeyPath<Element, T>) -> T {
        get {
            relay.value[keyPath: keyPath]
        }
    }
}

extension StateDriver: SharedSequenceConvertibleType {
    public func asSharedSequence() -> SharedSequence<DriverSharingStrategy, Element> {
        relay.asDriver()
    }
}

extension StateDriver: CustomStringConvertible where Element: CustomStringConvertible {
    public var description: String { relay.value.description }
}

extension StateDriver: CustomDebugStringConvertible where Element: CustomDebugStringConvertible {
    public var debugDescription: String { relay.value.debugDescription }
}
