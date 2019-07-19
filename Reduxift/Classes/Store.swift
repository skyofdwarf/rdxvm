//
//  Store.swift
//  SwiftTest
//
//  Created by skyofdwarf on 2019. 1. 26..
//  Copyright © 2019년 dwarfini. All rights reserved.
//

/// Store
///
/// `Store` dispatches `Action`s and publishes changes of `State`
public class Store<StateType: State> {
    public typealias Subscription = (_ state: StateType, _ action: Action) -> Void
    public typealias GetState = () -> StateType

    private typealias Warehouse = (dispatch: Dispatcher, getState: GetState)

    private var subscriptions: [Subscription] = []
    private var warehouse: Warehouse!

    #if DEBUG
    deinit {
        print("\(String(describing: self)).\(#function)")
    }
    #endif

    public init(state initialState: StateType,
                reducer: @escaping Reducer<StateType> = StateType.reduce,
                middlewares: [Middleware<StateType>] = [])
    {
        self.warehouse = createWarehouse(state: initialState,
                                         reducer: reducer,
                                         middlewares: middlewares)
    }

    /// Dispatches action
    /// - Parameter action: action to dispatch
    public func dispatch(_ action: Action) {
        let actions = (action as? Array<Action>) ?? [ action ]

        actions.forEach { _ = warehouse.dispatch($0) }
    }

    /// Subscribes to be notified actions
    /// - Parameter subscription: Subscription be called when action occurred
    public func subscribe(_ subscription: @escaping Subscription) {
        // TODO: Way to unsubscribe
        subscriptions.append(subscription)
    }

    /// Get current state
    public func getState() -> StateType {
        return warehouse.getState()
    }
}

extension Store {
    /*
     To avoid memory leaks by capture cycle between closures,
     the state is implemented as local variable being captured in `getState` interface closure.
     And closures related `dispatcher` interface, can `Never.do` when `self` is deallocated.
     */
    private func createWarehouse(state: StateType,
                                 reducer: @escaping Reducer<StateType>,
                                 middlewares: [Middleware<StateType>]) -> Warehouse
    {
        // State of the store is local variable and used/captured in below closures
        var state = state

        // Interface to get state
        let getState: GetState = { state }

        let rootDispatcher: Dispatcher = { [weak self = self] action -> Action in
            guard let self = self else { return Never.do }

            objc_sync_enter(self)
            defer { objc_sync_exit(self) }

            let actions = (action as? Array<Action>) ?? [ action ]

            for action in actions {
                state = reducer(state, action)

                self.subscriptions.forEach { (subscription) in
                    subscription(state, action)
                }
            }

            return action
        }

        let storeDispatcher: StoreDispatcher = { [weak self] in self?.dispatch($0) }

        // Interface to dispatch action
        let dispatcher = middlewares.reversed().reduce(rootDispatcher) { dispatcher, middleware in
            return middleware(getState, storeDispatcher)(dispatcher)
        }

        // Return tuple to interface with warehouse
        return (dispatcher, getState)
    }
}
