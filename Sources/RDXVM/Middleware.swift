//
//  Middleware.swift
//  RDXVM
//
//  Created by YEONGJUNG KIM on 2022/01/14.
//

import Foundation

public typealias Middleware<State, T> = (@escaping GetState<State>) -> MiddlewareTranducer<T>
public typealias GetState<State> = () -> State
public typealias MiddlewareTranducer<T> = (@escaping Dispatch<T>) -> Dispatch<T>
public typealias Dispatch<T> = (T) -> T

public typealias StatePostware<State> = StatePostwareTranducer<State>//() -> StatePostwareTranducer<State>
public typealias StatePostwareTranducer<State> = (@escaping Dispatch<State>) -> Dispatch<State>

/// Use this method to create a non-typed middleware for action, mutation, event, and error
/// - Parameter process: middleware logic
/// - Returns: a middleware
///
/// Middleware examples
///
/// * Non-typed middleware
///     ```swift
///     func logger<State, Input>(_ tag: String) -> Middleware<State, Input> {
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
///         ViewModelSubClass.middleware.action { state, next, action in
///             switch action {
///             case .start(let text):
///                 print("[\(tag)] got .start")
///             default:
///                 break
///             }
///             return next(action)
///         }
///     }
public func nontyped_middleware<State, T>(_ process: @escaping (_ state: GetState<State>, _ next: Dispatch<T>, _ action: T) -> T) -> Middleware<State, T> {
    { state in
        { next in
            { action in
                process(state, next, action)
            }
        }
    }
}

/// Use this method to create a non-typed state postware
/// - Parameter process: postware logic
/// - Returns: a state postware
///
/// Posteware examples
///
/// * Non-typed postware
///     ```swift
///     func logger<State, Input>(_ tag: String) -> Middleware<State, Input> {
///         nontyped_state_postware { state, next in
///             print("[\(tag)] \(state)")
///             return next(state)
///         }
///     }
///     ```
///
/// * Typed middleware
///     Use `ViewModel.postware(_:)` class method to create a typed middleware
///
///     ```
///     let typed_logger = { (tag: String) in
///         ViewModelSubClass.postware.state { state, next in
///             print("[\(tag)] \(state)")
///             return next(state)
///         }
///     }
public func nontyped_state_postware<State>(_ process: @escaping (_ state: State, _ next: Dispatch<State>) -> State) -> StatePostware<State> {
    { next in
        { state in
            // do ...
            // next(state)
            process(state, next)
        }
    }
}
