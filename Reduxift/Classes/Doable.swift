//
//  Doable.swift
//  Reduxift
//
//  Created by kimyj on 27/11/2019.
//  Copyright © 2019 kimyj. All rights reserved.
//

/// `Doable` can _do_ a side effect for `Action`, like async task or access to other resources.
///
/// To use,
/// 1. Conform `Action` to `Doable`
/// 2. Add `DoableMiddleware` to `Store`
public protocol Doable {
    /// You should return appropriate a Action that will be passed to chains of middleware instead of current Action.
    ///
    /// Return `self` just to pass current action
    /// Return `Never.do` to ignore middleware chains
    /// Or return whatever of `Action` fit intent.
    ///
    /// - Parameter dispatch: store dispatch function
    func `do`(_ dispatch: @escaping StoreDispatcher) -> Reaction
}

/// Simple side effect chaining model for `Doable`, and it's maybe a alternative of some `Middleware`.
public struct Doing: Action, Doable {
    typealias Before = () -> Void
    typealias After = (Reaction) -> Void

    private let source: Doable

    private var before: Before?
    private var after: After?

    init(source: Doable, before: Before?, after: After?) {
        self.source = source
        self.before = before
        self.after = after
    }

    public func `do`(_ dispatch: @escaping StoreDispatcher) -> Reaction {
        before?()

        let reaction = source.do(dispatch)

        after?(reaction)

        return reaction
    }
}

public extension Doable {
    func before(_ beforeClosure: @escaping () -> Void) -> Doing {
        return Doing(source: self, before: beforeClosure, after: nil)
    }

    func after(_ afterClosure: @escaping (Reaction) -> Void) -> Doing {
        return Doing(source: self, before: nil, after: afterClosure)
    }
}

