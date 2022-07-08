//
//  StateDriver.swift
//  RDXVM
//
//  Created by YEONGJUNG KIM on 2022/01/16.
//

import Foundation
import RxSwift
import RxRelay
import RxCocoa

/// StateDriver is a wrapper to drive new state/property or to get current property value.
///
/// You have 2 options to drive new values of state. You should use one way for consistency.
///
/// 1. To get a new state, drive this directly.
///     ```
///     struct State: ViewModelState {
///         let foo = 0
///         let bar = 1
///     }
///     vm.state
///         .drive(onNext: { state in
///             print(state.foo)
///             print(state.bar)
///      })
///     ```
///
/// 2. To get new values per property, drive @Driving property.
///     ```
///     struct State: ViewModelState {
///         @Driving var foo = 0
///         @Driving var bar = 1
///     }
///     vm.state.$foo
///         .drive(onNext: { foo in
///             print(foo)
///         })
///     ```
///
/// You can also get current value by accessing normal property.
///
///     ```
///     struct State: ViewModelState {
///         @Driving var foo = 0
///         let bar = 1
///     }
///     print(vm.state.foo)
///     print(vm.state.bar)
///     ```
@dynamicMemberLookup
public struct StateDriver<State: ViewModelState> {
    private let relay: BehaviorRelay<State>
    public init (_ relay: BehaviorRelay<State>) { self.relay = relay }
    
    /// get read-only raw state
    public var raw: State { relay.value }
    
    /// get @Driving property
    public subscript<T: SharedSequenceConvertibleType>(dynamicMember keyPath: KeyPath<State, T>) -> T {
        get {
            relay.value[keyPath: keyPath]
        }
    }
    
    /// get normal property
    public subscript<T>(dynamicMember keyPath: KeyPath<State, T>) -> T {
        get {
            relay.value[keyPath: keyPath]
        }
    }
}

extension StateDriver: SharedSequenceConvertibleType {
    public typealias SharingStrategy = DriverSharingStrategy
    public typealias Element = State
    
    public func asSharedSequence() -> SharedSequence<DriverSharingStrategy, Element> {
        relay.asDriver()
    }
}

extension StateDriver: CustomStringConvertible where State: CustomStringConvertible {
    public var description: String { relay.value.description }
}
