//
//  Middlewares.swift
//  RDXVMTests
//
//  Created by YEONGJUNG KIM on 2022/01/15.
//

import Foundation
@testable import RDXVM

// MARK: Action loggers

func action_logger_nontyped<State, Action>(_ tag: String) -> Middleware<State, Action> {
    nontyped_middleware { state, next, action in
        print("[\(tag)] BEFORE: \(action)")
        
        let a = next(action)
        
        print("[\(tag)] AFTER: \(action)")
        
        return a
    }
}

func action_logger_typed(_ tag: String) -> StateViewModel.ActionMiddleware {
    StateViewModel.middleware.action { state, next, action in
        print("[\(tag)] BEFORE: \(action)")
        
        let a = next(action)
        
        print("[\(tag)] AFTER: \(action)")
        
        return a
    }
}

func mutation_logger_nontyped<State, Mutation>(_ tag: String) -> Middleware<State, Mutation> {
    nontyped_middleware { state, next, mutation in
        print("[\(tag)] BEFORE: \(mutation)")
        
        let a = next(mutation)
        
        print("[\(tag)] AFTER: \(mutation)")
        
        return a
    }
}

func event_logger_nontyped<State, Event>(_ tag: String) -> Middleware<State, Event> {
    nontyped_middleware { state, next, event in
        print("[\(tag)] BEFORE: \(event)")
        
        let a = next(event)
        
        print("[\(tag)] AFTER: \(event)")
        
        return a
    }
}

func state_logger_nontyped<State>(_ tag: String) -> StatePostware<State> {
    nontyped_state_postware { state, next in
        
        print("[\(tag)] BEFORE: \(state)")
        
        let a = next(state)
        
        print("[\(tag)] AFTER: \(state)")
        
        return a
    }
}

// MARK: Typed middleware examples

func mutation_logger_typed(_ tag: String) -> StateViewModel.MutationMiddleware {
    StateViewModel.middleware.mutation { state, next, mutation in
        print("[\(tag)] BEFORE: \(mutation)")
        
        let a = next(mutation)
        
        print("[\(tag)] AFTER: \(mutation)")
        
        return a
    }
}

func event_logger_typed(_ tag: String) -> StateViewModel.EventMiddleware {
    StateViewModel.middleware.event { state, next, event in
        print("[\(tag)] BEFORE: \(event)")
        
        let a = next(event)
        
        print("[\(tag)] AFTER: \(event)")
        
        return a
    }
}

func state_logger_typed(_ tag: String) -> StateViewModel.StatePostware {
    StateViewModel.postware.state { state, next in
        
        print("[\(tag)] BEFORE: \(state)")

        let state = next(state)
        
        print("[\(tag)] AFTER: \(state)")
        
        return state
    }
}
