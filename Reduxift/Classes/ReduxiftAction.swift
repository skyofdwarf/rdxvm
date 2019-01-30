//
//  ReduxiftAction.swift
//  SwiftTest
//
//  Created by skyofdwarf on 2019. 1. 26..
//  Copyright © 2019년 dwarfini. All rights reserved.
//

import Foundation

/// action protocol
public protocol ReduxiftAction {
    var payload: Any? { get }
}


/// simple concrete action structure to use without implementing custom action things adopting ReduxiftAction protocol
public struct ReduxiftTagAction: ReduxiftAction {
    public let tag: String
    public let payload: Any?
    
    public init(_ tag: String, payload: Any? = nil) {
        self.tag = tag
        self.payload = payload
    }
}


public extension ReduxiftAction {
    /// canceller of async action
    public typealias AsyncCanceller = () -> Void
    
    /// payload of async action
    public typealias Async = (@escaping ReduxiftDispatcher) -> AsyncCanceller?
    
    
    typealias ActionReducer<State, Action: ReduxiftAction> = (_ state: State?, _ action: Action, _ defaults: State) -> State
    typealias AnyReducer<State> = (_ state: Any?, _ action: ReduxiftAction) -> State
    
    typealias GenericDispatcher<Action: ReduxiftAction> = (_ action: Action) -> Any
    typealias GenericAsync<Action: ReduxiftAction> = (@escaping GenericDispatcher<Action>) -> AsyncCanceller?
    
    
    
    /// default implementation
    var payload: Any? { return nil }
    
    
    /// creates async payload
    ///
    /// - Parameter action: action closure specified type of current concrete action
    /// - Returns: action closure type removed
    public func async(_ action: @escaping GenericAsync<Self>) -> Async {
        return Self.async(action)
    }
    
    public static func async(_ action: @escaping GenericAsync<Self>) -> Async {
        return action
    }


    /// creates reducer of action type
    ///
    /// - Parameters:
    ///   - defaults: default value of state
    ///   - reducer: closure to reduce state with action
    /// - Returns: state reducer
    public static func reduce<State>(_ defaults: State, _ reducer: @escaping ActionReducer<State, Self>) -> AnyReducer<State> {
        return { (state, action) in
            if action is Self {
                return reducer(state as? State, action as! Self, defaults)
            }
            else {
                return (state ?? defaults) as! State
            }
        }
    }
}


public extension ReduxiftTagAction {
    public static func reduce<State>(tag: String, _ defaults: State, _ reducer: @escaping ActionReducer<State, ReduxiftTagAction>) -> AnyReducer<State> {
        return { (state, action) in
            if let action = action as? ReduxiftTagAction, action.tag == tag {
                return reducer(state as? State, action, defaults)
            }
            else {
                return (state ?? defaults) as! State
            }
        }
    }
}
