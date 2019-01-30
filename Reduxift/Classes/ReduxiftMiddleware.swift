//
//  ReduxiftMiddleware.swift
//  RduxiftUI
//
//  Created by skyofdwarf on 2019. 1. 27..
//  Copyright © 2019년 dwarfini. All rights reserved.
//

import Foundation


/// dispatch transducer
public typealias ReduxiftDispatchTransducer = (_ next: @escaping ReduxiftDispatcher) -> ReduxiftDispatcher

/// type of middleware closure
public typealias ReduxiftMiddleware<State: ReduxiftState> = (_ state: @escaping ReduxiftStore<State>.GetState, _ dispatch: @escaping ReduxiftDispatcher) -> ReduxiftDispatchTransducer


/// helper flatted type of middleware process
public typealias MiddlewareProcess<State: ReduxiftState> = (
    _ state: @escaping ReduxiftStore<State>.GetState,
    _ dispatch: @escaping ReduxiftDispatcher,
    _ next: @escaping ReduxiftDispatcher,
    _ action: ReduxiftAction) -> Any



/// helper function to create middleware closure
///
/// - Parameter process: closure of middleware process
/// - Returns: middleware closure
public func CreateMiddleware<State: ReduxiftState>(_ process: @escaping MiddlewareProcess<State>) -> ReduxiftMiddleware<State> {
    return { (state, dispatch) in
        return { (next) in
            return { (action) in
                return process(state, dispatch, next, action)
            }
        }
    }
}


public typealias FunctionMiddlewareFunction<State: ReduxiftState> = (_ state: ReduxiftStore<State>.GetState, _ action: ReduxiftAction) -> Void

/// function middleware, calls a function before next middleware runs
///
/// - Parameter function: normal function to call
/// - Returns: function middleware closure
public func FunctionMiddleware<State: ReduxiftState>(_ function: @escaping FunctionMiddlewareFunction<State>) -> ReduxiftMiddleware<State> {
    return CreateMiddleware { (state, dispatch, next, action) in
        function(state, action)
        return next(action)
    }
}


/// middleware for async action
///
/// - Returns: async middleware closure
public func AsyncActionMiddleware<State: ReduxiftState>() -> ReduxiftMiddleware<State> {
    return CreateMiddleware { (state, dispatch, next, action) in
        if let async = action.payload as? ReduxiftAction.Async {
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
public func MainQueueMiddleware<State: ReduxiftState>() -> ReduxiftMiddleware<State> {
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
