//
//  Doable.swift
//  Reduxift
//
//  Created by kimyj on 27/11/2019.
//  Copyright © 2019 kimyj. All rights reserved.
//

/// `Doable` _do_ a side effect, like async task or access to other resources.
/// Conform `Doable` to do a side effect and apply `DoableMiddleware` to your `Store`.
public protocol Doable {
    typealias Do = (@escaping StoreDispatcher) -> Reaction

    func `do`(_ dispatch: @escaping StoreDispatcher) -> Reaction
}

public extension Doable {
    func `do`(_ dispatch: @escaping StoreDispatcher) -> Reaction { return Never.do }
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

