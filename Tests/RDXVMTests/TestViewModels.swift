//
//  TestViewModels.swift
//  RDXVMTests
//
//  Created by YEONGJUNG KIM on 2022/01/16.
//

import Foundation
import RxSwift
import RxRelay

@testable import RDXVM

struct Dependency {
    var games: [Game]
    var fruits: [Fruit]
}

final class StateViewModel: ViewModel<HappyAction, HappyMutation, HappyEvent, HappyState> {
    let dependency: Dependency
    init(dependency: Dependency,
         state initialState: HappyState,
         actionMiddlewares: [ActionMiddleware] = [],
         mutationMiddlewares: [MutationMiddleware] = [],
         eventMiddlewares: [EventMiddleware] = [],
         statePostwares: [StatePostware] = [])
    {
        self.dependency = dependency
        super.init(state: initialState,
                   actionMiddlewares: actionMiddlewares,
                   mutationMiddlewares: mutationMiddlewares,
                   eventMiddlewares: eventMiddlewares,
                   statePostwares: statePostwares)
    }
    
    override func react(action: Action, state: State) -> Observable<Reaction> {
        switch action {
        case .wakeup:
            return .of(.mutation(.status(.idle)),
                       .mutation(.ready(dependency.games, dependency.fruits)))
            
        case .play(let game):
            return .from([ .mutation(.status(.playing(game))),
                           .event(.win(game)) ])
            
        case .eat(let fruit):
            return .just(.mutation(.status(.eating(fruit))))
            
        case .shout(let message):
            return .just(.mutation(.lastMessage(message)))
            
        case .sleep(let seconds):
            return .just(.action(.wakeup)).delay(.seconds(seconds), scheduler: MainScheduler.asyncInstance)
                .startWith(.mutation(.status(.sleeping)))
        }
    }
    
    override func reduce(mutation: Mutation, state: inout State) {
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
    }
}

final class ErrorViewModel: ViewModel<HappyAction, HappyMutation, HappyEvent, HappyState> {
    init() {
        super.init(state: HappyState())
    }
    
    override func react(action: Action, state: State) -> Observable<Reaction> {
        let error = NSError(domain: "TestDomain", code: 3, userInfo: nil)
        return .error(error)
    }
}

final class DelegateViewModel: ViewModel<HappyAction, HappyMutation, HappyEvent, HappyState> {
    init() {
        super.init(state: HappyState())
    }
    
    override func react(action: Action, state: State) -> Observable<Reaction> {
        switch action {
        case .wakeup:
            return .just(.mutation(.status(.sleeping)))
        default:
            return .empty()
        }
    }
    
    override func reduce(mutation: Mutation, state: inout State) {
        switch mutation {
        case let .status(status):
            state.status = status
            state.count += 1
        default:
            break
        }
    }
}

final class DelegatingViewModel: ViewModel<HappyAction, HappyMutation, HappyEvent, HappyState> {
    let delegate = DelegateViewModel()
    let actionRelay = PublishRelay<DelegateViewModel.Action>()
    
    init() {
        super.init(state: HappyState())
        
        actionRelay
            .bind(to: delegate.action)
            .disposed(by: db)
    }
    
    override func react(action: Action, state: State) -> Observable<Reaction> {
        switch action {
        case .wakeup:
            actionRelay.accept(.wakeup)
        default:
            break
        }
        
        return .empty()
    }
    
    override func reduce(mutation: Mutation, state: inout State) {
        switch mutation {
        case let .status(status):
            state.status = status
            state.count += 1
        default:
            break
        }
    }
    
    override func transform(mutation: Observable<Mutation>) -> Observable<Mutation> {
        .merge(mutation,
               delegate.$state.$status.map { Mutation.status($0) }.asObservable())
    }
}
