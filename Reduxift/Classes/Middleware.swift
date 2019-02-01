//
//  Middleware.swift
//  RduxiftUI
//
//  Created by skyofdwarf on 2019. 1. 27..
//  Copyright © 2019년 dwarfini. All rights reserved.
//

import Foundation


/// dispatch transducer
public typealias DispatchTransducer = (_ next: @escaping Dispatcher) -> Dispatcher

/// type of middleware closure
public typealias Middleware<S: State> = (_ state: @escaping Store<S>.GetState, _ dispatch: @escaping Dispatcher) -> DispatchTransducer


/// helper flatted type of middleware process
public typealias MiddlewareProcess<S: State> = (
    _ state: @escaping Store<S>.GetState,
    _ dispatch: @escaping Dispatcher,
    _ next: @escaping Dispatcher,
    _ action: Action) -> Any



/// helper function to create middleware closure
///
/// - Parameter process: closure of middleware process
/// - Returns: middleware closure
public func CreateMiddleware<S: State>(_ process: @escaping MiddlewareProcess<S>) -> Middleware<S> {
    return { (state, dispatch) in
        return { (next) in
            return { (action) in
                return process(state, dispatch, next, action)
            }
        }
    }
}


public typealias FunctionMiddlewareFunction<State: State> = (_ state: Store<State>.GetState, _ action: Action) -> Void

/// function middleware, calls a function before next middleware runs
///
/// - Parameter function: normal function to call
/// - Returns: function middleware closure
public func FunctionMiddleware<S: State>(_ function: @escaping FunctionMiddlewareFunction<S>) -> Middleware<S> {
    return CreateMiddleware { (state, dispatch, next, action) in
        function(state, action)
        return next(action)
    }
}


/// middleware for async action
///
/// - Returns: async middleware closure
public func AsyncActionMiddleware<S: State>() -> Middleware<S> {
    return CreateMiddleware { (state, dispatch, next, action) in
        if let async = action.payload as? Action.Async {
            // do not call `next(action)`
            return async(dispatch) as Any
        }
        else {
            return next(action)
        }
    }
}


/// middleware to dispatch a action on main thread
///
/// - Returns: main queue middleware closure
public func MainQueueMiddleware<S: State>() -> Middleware<S> {
    return CreateMiddleware { (state, dispatch, next, action) in
        if Thread.isMainThread {
            return next(action)
        }
        else {
            DispatchQueue.main.async {
                _ = next(action)
            }
            return action
        }
    }
}
