//
//  State.swift
//  Reduxift
//
//  Created by skyofdwarf on 2019. 2. 1..
//

/// Implement reduce(_:_:) static method to use `State` for `Store`.
public protocol Reducible {
    static func reduce(_ state: Self, _ action: Action) -> Self
}

/// `State` is a data collection for Store.
public protocol State: Reducible {
}
