//
//  Middleware.swift
//  RduxiftUI
//
//  Created by skyofdwarf on 2019. 1. 27..
//  Copyright © 2019년 dwarfini. All rights reserved.
//

import Foundation

// MARK: - Middleware Types

/// dispatch transducer
public typealias DispatchTransducer = (_ next: @escaping Dispatcher) -> Dispatcher

/// type of middleware closure
public typealias Middleware<StateType: State> = (_ state: @escaping Store<StateType>.GetState, _ storeDispatch: @escaping StoreDispatcher) -> DispatchTransducer

/// helper flatted type of middleware process
public typealias MiddlewareProcess<StateType: State> = (
    _ getState: @escaping Store<StateType>.GetState, ///< store getState funcion
    _ storeDispatch: @escaping StoreDispatcher, ///< store dispach function
    _ nextMiddleware: @escaping Dispatcher, ///< next middleware
    _ action: Action) -> Action

/// helper function to create middleware closure
///
/// - Parameter process: closure of middleware process
/// - Returns: middleware closure
public func CreateMiddleware<StateType: State>(_ process: @escaping MiddlewareProcess<StateType>) -> Middleware<StateType> {
    return { (getState, storeDispatch) in
        return { (next) in
            return { (action) in
                return process(getState, storeDispatch, next, action)
            }
        }
    }
}

// MARK: - Default Middlewares

/// Calls `do(_:)` if `Action` conforms `Doable`.
///
/// if `Doable.do` method returns `Never.do`, then DoableMiddleware do stop calling chains of middleware.
/// - Returns: action middleware closure
public func DoableMiddleware<StateType: State>() -> Middleware<StateType> {
    return CreateMiddleware { (getState, storeDispatch, next, action) in
        guard let doable = action as? Doable else {
            return next(action)
        }

        let reaction = doable.do(storeDispatch)
        if reaction is Never.Do {
            return reaction
        }
        else {
            return next(reaction)
        }
    }
}

/// Calls logger function.
///
/// - Returns: custom log middleware closure
public func LogMiddleware<StateType: State>(_ tag: String = "LOG", _ logger: @escaping (String, Action, Store<StateType>.GetState) -> Void) -> Middleware<StateType> {
    return CreateMiddleware { (getState, storeDispatch, next, action) in
        logger(tag, action, getState)
        return next(action)
    }
}

/// Calls logger function after middleware chainig.
///
/// - Returns: custom log middleware closure
public func LazyLogMiddleware<StateType: State>(_ tag: String = "LOG", _ logger: @escaping (String, Action, Store<StateType>.GetState) -> Void) -> Middleware<StateType> {
    return CreateMiddleware { (getState, storeDispatch, next, action) in
        defer { logger(tag, action, getState) }
        return next(action)
    }
}

/// Make `Action` be dispatched in main thread.
///
/// - Returns: main thread middleware closure
public func MainThreadMiddleware<StateType: State>() -> Middleware<StateType> {
    return CreateMiddleware { (getState, storeDispatch, next, action) in
        if Thread.isMainThread {
            return next(action)
        }
        else {
            DispatchQueue.main.async {
                _ = next(action)
            }
        }

        return Never.do
    }
}
