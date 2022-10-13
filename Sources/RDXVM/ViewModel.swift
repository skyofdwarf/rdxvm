//
//  ViewModel.swift
//  RDXVM
//
//  Created by YEONGJUNG KIM on 2022/01/14.
//

import Foundation
import RxSwift
import RxRelay
import RxCocoa

/// Redux like ViewModel class.
///
/// Bind actions with `action` property and bind `state`, `event` and `error` properties to get data, evnets and uncatched or explicit errors.
open class ViewModel<Action,
                     Mutation,
                     Event,
                     State>
{
    // MARK: - Types
    
    public typealias Action = Action
    public typealias Mutation = Mutation
    public typealias Event = Event
    public typealias State = State    
    
    /// Reaction is a response or side-effect of an action
    ///
    /// - Note: Reaction.action is scheduled next runloop to prevent reentrancy to reacting process(Rx reentrancy)
    public enum Reaction {
        case action(Action)
        case mutation(Mutation)
        case event(Event)
        case error(Error)
    }
    
    // MARK: - Input
    
    /// Action input function
    public func send(action: Action) {
        userActionRelay.accept(action)
    }
    
    /// Action input binder, use it to send an action in RX way
    public var action: Binder<Action> {
        Binder<Action>(self) { base, action in
            base.userActionRelay.accept(action)
        }
    }
    
    // MARK: - Output
    
    /// Error output signal
    public var error: Signal<Error> { errorRelay.asSignal() }
    
    /// Event output signal
    public var event: Signal<Event> { eventRelay.asSignal() }
    
    /// State drivable output
    public var state: StateDriver<State> { StateDriver(stateRelay) }
    
    // MARK: - Private properties
    
    private(set) var db = DisposeBag()
    
    fileprivate let userActionRelay = PublishRelay<Action>()
    fileprivate let eventRelay = PublishRelay<Event>()
    fileprivate let errorRelay = PublishRelay<Error>()
    fileprivate let stateRelay: BehaviorRelay<State>
    
    deinit {
#if DEBUG
        print("deinit: \(self)")
#endif
    }
    
    // MARK: - Intializer
    
    /// Initializes a view model with state, middlewares, and postwares
    /// - Parameters:
    ///   - initialState: initial state
    ///   - actionMiddlewares: action middlewares
    ///   - mutationMiddlewares: mutation middlewares
    ///   - eventMiddlewares: event middlewares
    ///   - errorMiddlewares: error middlewares
    ///   - statePostwares: state postwares
    public init(state initialState: State,
                actionMiddlewares: [ActionMiddleware] = [],
                mutationMiddlewares: [MutationMiddleware] = [],
                eventMiddlewares: [EventMiddleware] = [],
                errorMiddlewares: [ErrorMiddleware] = [],
                statePostwares: [StatePostware] = [])
    {
        // state
        stateRelay = BehaviorRelay<State>(value: initialState)
        
        let rawErrorRelay = PublishRelay<Error>()
        let actionRelay = PublishRelay<Action>()
        let reactionRelay = PublishRelay<Reaction>()
        let mutationRelay = PublishRelay<Mutation>()
        
        let dispatchAction = Self.dispatcher(actionMiddlewares, actionRelay, stateRelay)
        let dispatchMutation = Self.dispatcher(mutationMiddlewares, mutationRelay, stateRelay)
        let dispatchEvent = Self.dispatcher(eventMiddlewares, eventRelay, stateRelay)
        let dispatchError = Self.dispatcher(errorMiddlewares, errorRelay, stateRelay)
        let statePostware = Self.statePostware(statePostwares)
        
        // ACTION: react(middleware(transform(action))) -> reaction
        
        // 1. user action, reaction.action
        let action = Observable<Action>.merge([
            userActionRelay.asObservable(),
            reactionRelay.compactMap{ $0.action }
                .observe(on: MainScheduler.asyncInstance) /* prevent reentrancy */
        ])
        
        // 2. middleware(transform(action)) -> processed action
        transform(action: action)
            .subscribe(onNext: {
                _ = dispatchAction($0)
            })
            .disposed(by: db)
        
        // 3. react(processed action) -> reaction
        actionRelay
            .withLatestFrom(stateRelay) { ($0, $1) }
            .flatMap { [weak self] (action, state) -> Observable<Reaction> in
                guard let self else { return .empty() }
                return self.react(action: action, state: state)
                    .catch {
                        rawErrorRelay.accept($0)
                        return .empty()
                    }
            }
            .bind(to: reactionRelay)
            .disposed(by: db)
        
        // Mutation: middleware(transform(reaction.mutation)) -> mutation
        transform(mutation: reactionRelay.compactMap { $0.mutation })
            .subscribe(onNext: {
                _ = dispatchMutation($0)
            })
            .disposed(by: db)
        
        // Event: middleware(transform(reaction.event) -> event
        transform(event: reactionRelay.compactMap { $0.event })
            .subscribe(onNext: {
                _ = dispatchEvent($0)
            })
            .disposed(by: db)
        
        // Error: middleware(transform(error)) -> error
        reactionRelay.compactMap { $0.error }
            .bind(to: rawErrorRelay)
            .disposed(by: db)
        
        transform(error: rawErrorRelay.asObservable())
            .subscribe(onNext: {
                _ = dispatchError($0)
            })
            .disposed(by: db)
        
        // State: postware(reduce(mutation)) -> state
        mutationRelay
            .scan(initialState) { [weak self] state, mutation in
                guard let self else { return state }
                return self.reduce(mutation: mutation, state: state)
            }
            .map { statePostware($0) }
            .bind(to: stateRelay)
            .disposed(by: db)
    }
    
    // MARK: - Reactor
    
    /// Action react method.
    /// You should override this method to map an action to an observable of reactions.
    /// You can do asynchronous jobs in here and return `.mutations` to mutate the state, or `.event` to signal some event like an error to a user
    /// - Parameters:
    ///   - action: action to react
    ///   - state: current state
    /// - Returns: an observable of reactions
    open func react(action: Action, state: State) -> Observable<Reaction> {
        .empty()
    }
    
    // MARK: - Reducer
    
    /// State reducer method.
    /// You should override this method to configure the state with mutation.
    /// - Parameters:
    ///   - mutation: a mutation
    ///   - state: current state
    /// - Returns: new state
    open func reduce(mutation: Mutation, state: State) -> State {
        state
    }

    // MARK: - Transformers
    
    /// Transforms action
    /// You can override to transform actions
    /// - Note: The transformed observable must not throw an error.
    open func transform(action: Observable<Action>) -> Observable<Action> {
        action
    }
    
    /// Transforms mutation
    /// /// /// You can override to transform mutations
    /// - Note: The transformed observable must not throw an error.
    open func transform(mutation: Observable<Mutation>) -> Observable<Mutation> {
        mutation
    }
    
    /// Transforms event
    /// /// You can override to transform events
    /// - Note: The transformed observable must not throw an error.
    open func transform(event: Observable<Event>) -> Observable<Event> {
        event
    }
    
    /// Transforms error
    /// /// /// You can override to transform errors
    /// - Note: The transformed observable must not throw an error.
    open func transform(error: Observable<Error>) -> Observable<Error> {
        error
    }
}

private extension ViewModel.Reaction {
    var action: Action? {
        guard case let .action(action) = self else { return nil }
        return action
    }
    var mutation: Mutation? {
        guard case let .mutation(mutation) = self else { return nil }
        return mutation
    }
    var event: Event? {
        guard case let .event(event) = self else { return nil }
        return event
    }
    var error: Error? {
        guard case let .error(error) = self else { return nil }
        return error
    }
}

// MARK: - Dispatcher

private extension ViewModel {
    /// Makes dispatch function of Action/Mutation/Event with middlewares
    /// - Parameter middlewares: middlewares
    /// - Parameter dispatchRelay: A relay to dispatch a action/mutation/event passed all middlewares
    /// - Parameter stateRelay: A relay to get a state
    /// - Returns: A dispatch function
    static func dispatcher<T>(_ middlewares: [Middleware<T>],
                              _ dispatchRelay: PublishRelay<T>,
                              _ stateRelay: BehaviorRelay<State>) -> Dispatch<T> {
        { middlewares, dispatchRelay, stateRelay in
            let rawDispatch: Dispatch<T> = { dispatchRelay.accept($0); return $0 }
            let getState: GetState = { stateRelay.value }
            
            return middlewares.reversed().reduce(rawDispatch) { dispatch, mw in
                return mw(getState)(dispatch)
            }
        }(middlewares, dispatchRelay, stateRelay)
    }
        
    /// Makes postware stack for state.
    /// - Parameter middlewares: state middlewares
    /// - Returns: A state middleware stack function
    static func statePostware(_ postwares: [StatePostware]) -> (State) -> State {
        let rawState: Dispatch<State> = { $0 }
        
        let f: Dispatch<State> = postwares.reversed().reduce(rawState) { mwStack, mw in
            return mw(mwStack)
        }
        
        return { f($0) }
    }
}

// MARK: - Middleware/Postware

public extension ViewModel {
    typealias ActionMiddleware = Middleware<Action>
    typealias MutationMiddleware = Middleware<Mutation>
    typealias EventMiddleware = Middleware<Event>
    typealias ErrorMiddleware = Middleware<Error>
    
    typealias GetState = () -> State
    typealias Dispatch<What> = (What) -> What
    typealias Middleware<What> = (@escaping GetState) -> MiddlewareTranducer<What>
    typealias MiddlewareTranducer<What> = (@escaping Dispatch<What>) -> Dispatch<What>
    
    typealias StatePostware = StatePostwareTranducer//() -> StatePostwareTranducer
    typealias StatePostwareTranducer = (@escaping Dispatch<State>) -> Dispatch<State>
    
    /// Middleware helper type
    struct MiddlewareGenerator {
        public func action(_ process: @escaping (_ state: GetState, _ next: Dispatch<Action>, _ action: Action) -> Action) -> Middleware<Action> {
            nontyped_middleware(process)
        }
        public func mutation(_ process: @escaping (_ state: GetState, _ next: Dispatch<Mutation>, _ mutation: Mutation) -> Mutation) -> Middleware<Mutation> {
            nontyped_middleware(process)
        }
        public func event(_ process: @escaping (_ state: GetState, _ next: Dispatch<Event>, _ event: Event) -> Event) -> Middleware<Event> {
            nontyped_middleware(process)
        }
        public func error(_ process: @escaping (_ state: GetState, _ next: Dispatch<Error>, _ error: Error) -> Error) -> Middleware<Error> {
            nontyped_middleware(process)
        }
    }
    
    /// Postware helper type
    struct PostwareGenerator {
        public func state(_ process: @escaping (_ state: State, _ next: Dispatch<State>) -> State) -> StatePostware {
            nontyped_state_postware(process)
        }
    }
    
    /// Middleware generator
    static var middleware: MiddlewareGenerator { MiddlewareGenerator() }
    
    /// Postware generator
    static var postware: PostwareGenerator { PostwareGenerator() }
}
