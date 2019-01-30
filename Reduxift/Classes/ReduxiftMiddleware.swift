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
public typealias ReduxiftMiddleware = (_ state: @escaping ReduxiftStore.GetState, _ dispatch: @escaping ReduxiftDispatcher) -> ReduxiftDispatchTransducer


/// helper flatted type of middleware process
public typealias MiddlewareProcess = (
    _ state: @escaping ReduxiftStore.GetState,
    _ dispatch: @escaping ReduxiftDispatcher,
    _ next: @escaping ReduxiftDispatcher,
    _ action: ReduxiftAction) -> Any



/// helper function to create middleware closure
///
/// - Parameter process: closure of middleware process
/// - Returns: middleware closure
public func CreateMiddleware(_ process: @escaping MiddlewareProcess) -> ReduxiftMiddleware {
    return { (state, dispatch) in
        return { (next) in
            return { (action) in
                return process(state, dispatch, next, action)
            }
        }
    }
}


public typealias FunctionMiddlewareFunction = (_ state: ReduxiftStore.GetState, _ action: ReduxiftAction) -> Void

/// function middleware, calls a function before next middleware runs
///
/// - Parameter function: normal function to call
/// - Returns: function middleware closure
public func FunctionMiddleware(_ function: @escaping FunctionMiddlewareFunction) -> ReduxiftMiddleware {
    return CreateMiddleware { (state, dispatch, next, action) in
        function(state, action)
        return next(action)
    }
}


/// middleware for async action
///
/// - Returns: async middleware closure
public func AsyncActionMiddleware() -> ReduxiftMiddleware {
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
public func MainQueueMiddleware() -> ReduxiftMiddleware {
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
