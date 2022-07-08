//
//  Middleware.swift
//  RDXVM
//
//  Created by YEONGJUNG KIM on 2022/01/14.
//

import Foundation

public typealias Middleware<State: ViewModelState, T> = (@escaping GetState<State>) -> MiddlewareTranducer<T>
public typealias GetState<State: ViewModelState> = () -> State
public typealias MiddlewareTranducer<T> = (@escaping Dispatch<T>) -> Dispatch<T>
public typealias Dispatch<T> = (T) -> T

public typealias StateMiddleware<State: ViewModelState> = StateMiddlewareTranducer<State>//() -> StateMiddlewareTranducer<State>
public typealias StateMiddlewareTranducer<State: ViewModelState> = (@escaping Dispatch<State>) -> Dispatch<State>

/// Use this method to create a non-typed middleware
/// - Parameter process: middleware logic
/// - Returns: a middleware
///
/// Middleware examples
///
/// * Non-typed middleware
///     ```swift
///     func logger<State: ViewModelState, Input: ViewModelInput>(_ tag: String) -> Middleware<State, Input> {
///         nontyped_middleware { state, next, action in
///             print("[\(tag)] \(action)")
///             return next(action)
///         }
///     }
///     ```
///
/// * Typed middleware
///     Use `ViewModel.middleware(_:)` class method to create a typed middleware
///
///     ```
///     let typed_logger = { (tag: String) in
///         ViewModelSubClass.middleware { state, next, action in
///             switch action {
///             case .start(let text):
///                 print("[\(tag)] got .start")
///             default:
///                 break
///             }
///             return next(action)
///         }
///     }
public func nontyped_middleware<State: ViewModelState, T>(_ process: @escaping (_ state: GetState<State>, _ next: Dispatch<T>, _ action: T) -> T) -> Middleware<State, T> {
    { state in
        { next in
            { action in
                process(state, next, action)
            }
        }
    }
}

public func nontyped_state_middleware<State: ViewModelState>(_ process: @escaping (_ state: State, _ next: Dispatch<State>) -> State) -> StateMiddleware<State> {
    { next in
        { state in
            // do ...
            // next(state)
            process(state, next)
        }
    }
}
