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
