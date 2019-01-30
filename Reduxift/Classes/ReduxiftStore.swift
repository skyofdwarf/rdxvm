//
//  ReduxiftStore.swift
//  SwiftTest
//
//  Created by skyofdwarf on 2019. 1. 26..
//  Copyright © 2019년 dwarfini. All rights reserved.
//

import Foundation



/// store subscriber delegate
public protocol ReduxiftStoreSubscriber: class {
    func store(didChangeState state: ReduxiftStore.State, action: ReduxiftAction)
}



/// ReduxiftStore
public class ReduxiftStore {
    public typealias State = Dictionary<String, Any>
    public typealias Reducer = (_ state: State, _ action: ReduxiftAction) -> State
    public typealias GetState = () -> State
    
    
    public private(set) var state: State = [:]
    
    private var subscribers = NSHashTable<AnyObject>.weakObjects()
    private var reducer: Reducer
    private var dispatcher: ReduxiftDispatcher!
    
    private var dispatching: Bool = false
    
    public init(state: State, reducer: @escaping Reducer, middlewares: [ReduxiftMiddleware]) {
        self.reducer = reducer
        self.dispatcher = self.buildDispatcher(middlewares: middlewares)
    }
    
    public convenience init(state: State, reducer: @escaping Reducer) {
        self.init(state: state, reducer: reducer, middlewares: [])
    }
    
    private func buildDispatcher(middlewares: [ReduxiftMiddleware]) -> ReduxiftDispatcher {
        let dispatcher: ReduxiftDispatcher = { [unowned self] (action) in
            guard !self.dispatching else {
                fatalError("a store can't dispatch a action while processing other action already dispatched: \(action)")
            }
            self.dispatching = true
            
            self.state = self.reducer(self.state, action)
            self.publish(self.state, action)
            
            self.dispatching = false
            
            return action
        }
        
        let getState: ReduxiftStore.GetState = { [unowned self] in self.state }
        let storeDispatcher: ReduxiftDispatcher = { [unowned self] (action) in self.dispatcher(action) }
        
        return middlewares.reversed().reduce(dispatcher) { (dispatcher, mw) -> ReduxiftDispatcher in
            return mw(getState, storeDispatcher)(dispatcher)
        }
    }
    
    @discardableResult
    public func dispatch(_ action: ReduxiftAction) -> Any {
        return self.dispatcher(action)
    }
    
    public func subscribe(_ subscriber: ReduxiftStoreSubscriber) {
        self.subscribers.add(subscriber)
    }
    
    public func unsubscribe(_ subscriber: ReduxiftStoreSubscriber) {
        self.subscribers.remove(subscriber)
    }
    
    private func publish(_ state: State, _ action: ReduxiftAction) {
        self.subscribers.allObjects.forEach { (obj) in
            if let subscriber = obj as? ReduxiftStoreSubscriber {
                subscriber.store(didChangeState: state, action: action)
            }
        }
    }

    public static func reducer(_ reducer: @escaping Reducer) -> Reducer {
        return reducer
    }
}

