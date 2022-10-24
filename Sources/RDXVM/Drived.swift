//
//  Drived.swift
//  RDXVM
//
//  Created by YEONGJUNG KIM on 2022/01/14.
//

import Foundation
import RxSwift
import RxRelay
import RxCocoa

/// Property wrapper to get a new value of a property instead of a state value.
///
/// You can use wrapped property like normal property.
/// ```
/// struct State {
///     @Drived var foo = 0
///     var bar = 1
/// }
///
/// // get a value
/// print("current foo: \(vm.state.foo)")
///
/// // set a value in reducer
/// func reduce(mutation, state) {
///     state.foo = 1
///     state.bar = 2
/// }
/// ```
///
/// Conforms `SharedSequenceConvertibleType` to drive new values of property.
///
/// ```
/// struct State {
///     @Drived var foo = 0
///     var bar = 1
/// }
/// vm.state.$foo.drive()
/// ```
@propertyWrapper
public struct Drived<Element> {
    public var wrappedValue: Element {
        get {
            relay.value
        }
        set {
            relay.accept(newValue)
        }
    }
    
    public var projectedValue: Driver<Element> { relay.asDriver() }
    private let relay: BehaviorRelay<Element>
    
    public init(wrappedValue: Element) {
        self.relay = BehaviorRelay<Element>(value: wrappedValue)
    }
}
