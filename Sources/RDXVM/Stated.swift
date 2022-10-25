//
//  Stated.swift
//  RDXVM
//
//  Created by YEONGJUNG KIM on 2022/10/24.
//

import RxSwift
import RxRelay
import RxCocoa

/// Stated is a simple property wrapper to get the current state value of the state.
///
/// ```
/// struct State {
///     let foo = 0
/// }
///
/// print(vm.$state)
/// ```
///
/// To get current property value of the state, `$` can be omitted.
/// ```
/// struct State {
///     let foo = 0
/// }
/// vm.$state.foo
/// vm.state.foo
/// ```
@propertyWrapper
public struct Stated<Element> {
    public var wrappedValue: StateDriver<Element>
    public var projectedValue: Element { wrappedValue.relay.value }

    public init(wrappedValue: StateDriver<Element>) {
        self.wrappedValue = wrappedValue
    }
}
