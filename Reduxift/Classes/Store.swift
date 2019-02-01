//
//  Store.swift
//  SwiftTest
//
//  Created by skyofdwarf on 2019. 1. 26..
//  Copyright © 2019년 dwarfini. All rights reserved.
//

import Foundation


/// workaround protocol to workaround compile error of using a protocol with associated type
///
/// - Note: public but dont use in your app
///
/// workaround below compile error
/// `Protocol 'protocol-name' can only be used as a generic constraint because it has Self or associated type requirements.`
///
public protocol StoreBaseSubscriber {
    func callDelegate(state: State, action: Action)
}

public extension StoreSubscriber {
    /// call real delegate function of subscriber
    func callDelegate(state: State, action: Action) {
        self.store(didChangeState: state as! S, action: action)
    }
}

/// store subscriber delegate
public protocol StoreSubscriber: class, StoreBaseSubscriber {
    associatedtype S: State
    func store(didChangeState state: S, action: Action)
}



/// typealiases for dictionary state
public typealias DictionaryState = [String: Any]
public typealias DictionaryStore = Store<DictionaryState>

    
/// Store
///
/// Reduxift publishes not only new state but also the action which is cause of publishing
public class Store<S: State> {
    public typealias Reducer = (_ state: S, _ action: Action) -> S
    public typealias GetState = () -> S
    
    public private(set) var state: S = S()
    
    
    private var subscribers = NSHashTable<AnyObject>.weakObjects()
    private var reducer: Reducer
    private var dispatcher: Dispatcher!
    
    private var dispatching: Bool = false
    
    public init(state: S, reducer: @escaping Reducer, middlewares: [Middleware<S>]) {
        self.reducer = reducer
        self.dispatcher = self.buildDispatcher(middlewares: middlewares)
    }
    
    public convenience init(state: S, reducer: @escaping Reducer) {
        self.init(state: state, reducer: reducer, middlewares: [])
    }
    
    private func buildDispatcher(middlewares: [Middleware<S>]) -> Dispatcher {
        let dispatcher: Dispatcher = { [unowned self] (action) in
            guard !self.dispatching else {
                fatalError("a store can't dispatch a action while processing other action already dispatched: \(action)")
            }
            self.dispatching = true
            
            self.state = self.reducer(self.state, action)
            self.publish(self.state, action)
            
            self.dispatching = false
            
            return action
        }
        
        let getState: Store.GetState = { [unowned self] in self.state }
        let storeDispatcher: Dispatcher = { [unowned self] (action) in self.dispatcher(action) }
        
        return middlewares.reversed().reduce(dispatcher) { (dispatcher, mw) -> Dispatcher in
            return mw(getState, storeDispatcher)(dispatcher)
        }
    }
    
    @discardableResult
    public func dispatch(_ action: Action) -> Any {
        return self.dispatcher(action)
    }
    
    public func subscribe<T: StoreSubscriber>(_ subscriber: T) {
        self.subscribers.add(subscriber)
    }
    
    public func unsubscribe<T: StoreSubscriber>(_ subscriber: T) {
        self.subscribers.remove(subscriber)
    }
    
    private func publish(_ state: S, _ action: Action) {
        self.subscribers.allObjects.forEach { (obj) in
            if let subscriber = obj as? StoreBaseSubscriber {
                subscriber.callDelegate(state: state, action: action)
            }
        }
    }
    
    public static func reduce(_ reducer: @escaping Reducer) -> Reducer {
        return reducer
    }
}

