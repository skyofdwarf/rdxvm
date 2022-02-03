//
//  TestViewModels.swift
//  ReduxiftTests
//
//  Created by YEONGJUNG KIM on 2022/01/16.
//

import Foundation
import RxSwift

@testable import Reduxift

struct Dependency {
    var games: [Game]
    var fruits: [Fruit]
}

final class StateViewModel: ViewModel<HappyAction, HappyMutation, HappyState, HappyEvent> {
    let dependency: Dependency
    init(dependency: Dependency,
         state initialState: HappyState,
         actionMiddlewares: [ActionMiddleware] = [],
         mutationMiddlewares: [MutationMiddleware] = [],
         eventMiddlewares: [EventMiddleware] = [],
         stateMiddlewares: [StateMiddleware] = [])
    {
        self.dependency = dependency
        super.init(state: initialState,
                   actionMiddlewares: actionMiddlewares,
                   mutationMiddlewares: mutationMiddlewares,
                   eventMiddlewares: eventMiddlewares,
                   stateMiddlewares: stateMiddlewares)
    }
    
    override func react(action: Action, state: State) -> Observable<Reaction> {
        switch action {
        case .wakeup:
            return .just(.mutation(.ready(dependency.games, dependency.fruits)))
            
        case .play(let game):
            return .from([ .mutation(.status(.playing(game))),
                           .event(.win(game)) ])
            
        case .eat(let fruit):
            return .just(.mutation(.status(.eating(fruit))))
            
        case .shout(let message):
            return .just(.mutation(.lastMessage(message)))
        }
    }
    
    override func reduce(mutation: Mutation, state: State) -> State {
        var state = state
        switch mutation {
        case .lastMessage(let text):
            state.lastMessage = text
            state.count += 1
            
        case let .ready(games, fruits):
            state.games = games
            state.fruits = fruits
            state.count += 1
            
        case let .status(status):
            state.status = status
            state.count += 1
        }
        
        return state
    }
}

final class DrivingStateViewModel: ViewModel<HappyAction, HappyMutation, DrivingHappyState, HappyEvent> {
    let dependency: Dependency
    init(dependency: Dependency, state initialState: DrivingHappyState) {
        self.dependency = dependency
        super.init(state: initialState)
    }
    
    override func react(action: Action, state: State) -> Observable<Reaction> {
        switch action {
        case .wakeup:
            return .just(.mutation(.ready(dependency.games, dependency.fruits)))
            
        case .play(let game):
            return .from([ .mutation(.status(.playing(game))),
                           .event(.win(game)) ])
            
        case .eat(let fruit):
            return .just(.mutation(.status(.eating(fruit))))
            
        case .shout(let message):
            return .just(.mutation(.lastMessage(message)))
        }
    }
    
    override func reduce(mutation: Mutation, state: State) -> State {
        var state = state
        switch mutation {
        case .lastMessage(let text):
            state.lastMessage = text
            state.count += 1
            
        case let .ready(games, fruits):
            state.games = games
            state.fruits = fruits
            state.count += 1
            
        case let .status(status):
            state.status = status
            state.count += 1
        }
        
        return state
    }
}

final class ErrorViewModel: ViewModel<HappyAction, HappyMutation, HappyState, HappyEvent> {
    init() {
        super.init(state: HappyState())
    }
    
    override func react(action: Action, state: State) -> Observable<Reaction> {
        let error = NSError(domain: "TestDomain", code: 3, userInfo: nil)
        return .error(error)
    }
    
    override func reduce(mutation: Mutation, state: State) -> State {
        return state
    }
}
