//
//  Action.swift
//  SwiftTest
//
//  Created by skyofdwarf on 2019. 1. 26..
//  Copyright © 2019년 dwarfini. All rights reserved.
//

// MARK: - Action

/// `Action` is a thing that causes `State` changes.
public protocol Action {
}


// MARK: - Reaction

/// `Reaction` is `Action`, but type aliased to mean that is side effect of an action dispatched in advance.
public typealias Reaction = Action



// MARK: - Extensions

extension NSNull: Action {}

public extension Never {
    /// `Never.do` means that _no reaction_.
    ///
    /// `Doable.do` method can return `Never.do` to mean _no reaction_.
    static var `do`: Do { return Do() }

    /// `Never.Do` can be used to match an action with `Never.do`.
    ///
    /// ```
    /// if action is Never.Do {
    /// }
    /// ```
    typealias Do = NSNull
}

/// `String` can be used for `Action`.
extension String: Action {}


/// Array of `Action` can be dispatched. but `Store` will process actions in order.
///
/// ```
/// store.dispatch([ action1, action2 ])
/// ```
extension Array: Action where Element == Action {
}
