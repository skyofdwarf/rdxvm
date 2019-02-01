//
//  Action.swift
//  SwiftTest
//
//  Created by skyofdwarf on 2019. 1. 26..
//  Copyright © 2019년 dwarfini. All rights reserved.
//

import Foundation


/// action protocol
public protocol Action {
    var payload: Any? { get }
}

public extension Action {
    /// canceller of async action
    public typealias AsyncCanceller = () -> Void
    
    /// payload of async action
    public typealias Async = (@escaping Dispatcher) -> AsyncCanceller?
    
    
    typealias ActionReducer<State, A: Action> = (_ state: State, _ action: A) -> State
    typealias PayloadReducer<State> = (_ state: State, _ payload: State?) -> State
    typealias AnyReducer<State> = (_ state: Any?, _ action: Action) -> State
    
    typealias GenericDispatcher<A: Action> = (_ action: A) -> Any
    typealias GenericAsync<A: Action> = (@escaping GenericDispatcher<A>) -> AsyncCanceller?
    

    /// default payload implementation
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
                return reducer((state ?? defaults) as! State, action as! Self)
            }
            else {
                return (state ?? defaults) as! State
            }
        }
    }
}


public protocol ActionNaming: Action {
    var name: String { get }
}


/// simple concrete action structure to use without implementing custom action things adopting Action protocol
public struct NamedAction: ActionNaming {
    public let name: String
    public let payload: Any?

    public init(_ name: String, payload: Any? = nil) {
        self.name = name
        self.payload = payload
    }
}

public extension NamedAction {
    public static func reduce<State>(name: String, _ defaults: State, _ reducer: @escaping PayloadReducer<State>) -> AnyReducer<State> {
        return { (state, action) in
            if let action = action as? ActionNaming, action.name == name {
                return reducer((state ?? defaults) as! State, action.payload as? State)
            }
            else {
                return (state ?? defaults) as! State
            }
        }
    }
}

extension String  {
    public func payload(_ p: Any) -> ActionNaming {
        return NamedAction(self, payload: p)
    }
}
