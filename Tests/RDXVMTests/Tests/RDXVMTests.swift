//
//  RDXVMTests.swift
//  RDXVMTests
//
//  Created by YEONGJUNG KIM on 2022/01/14.
//

import XCTest
import RxSwift
import RxRelay
@testable import RDXVM

class RDXVMTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func test_state() throws {
        var db = DisposeBag()
        
        let dependency = Dependency(games: [.lol, .wow], fruits: [.apple, .cherry])
        let state = HappyState(lastMessage: nil,
                               status: .idle,
                               games: [.lol],
                               fruits: [.apple])
        let vm = StateViewModel(dependency: dependency, state: state)
        
        XCTAssert(vm.state.lastMessage == nil)
        XCTAssert(vm.state.status == .idle)
                
        let actionRelay = PublishRelay<HappyAction>()
        
        actionRelay.bind(to: vm.action)
            .disposed(by: db)
        
        actionRelay.accept(.wakeup)
        XCTAssert(vm.state.games == dependency.games)
        XCTAssert(vm.state.fruits == dependency.fruits)
        XCTAssert(vm.state.count == 2)
        
        actionRelay.accept(.play(.wow))
        XCTAssert(vm.state.status == .playing(.wow))
        XCTAssert(vm.state.count == 3)
        
        actionRelay.accept(.eat(.cherry))
        XCTAssert(vm.state.status == .eating(.cherry))
        XCTAssert(vm.state.count == 4)
        
        actionRelay.accept(.eat(.apple))
        XCTAssert(vm.state.status == .eating(.apple))
        XCTAssert(vm.state.count == 5)
        
        let message_rock = "I wanna ROCK !"
                      
        actionRelay.accept(.shout(message_rock))
        XCTAssert(vm.state.lastMessage == message_rock)
        XCTAssert(vm.state.count == 6)
        
        db = DisposeBag()
        
        let message_hear = "You hear me?"
        
        actionRelay.accept(.shout(message_hear))
        
        XCTAssert(vm.state.lastMessage != message_hear)
        XCTAssert(vm.state.lastMessage == message_rock)
        XCTAssert(vm.state.count == 6)
        
        actionRelay.bind(to: vm.action)
            .disposed(by: db)
        
        actionRelay.accept(.shout(message_hear))
        
        XCTAssert(vm.state.lastMessage == message_hear)
        XCTAssert(vm.state.count == 7)
        
        XCTAssertEqual(vm.$state,
                       HappyState(lastMessage: message_hear,
                                  status: .eating(.apple),
                                  games: dependency.games,
                                  fruits: dependency.fruits,
                                  count: 7))
    }
    
    func test_state_drive() throws {
        let db = DisposeBag()
        
        let dependency = Dependency(games: [.lol, .wow], fruits: [.apple, .cherry])
        let state = HappyState(lastMessage: nil,
                               status: .idle,
                               games: [.lol],
                               fruits: [.apple])
        let vm = StateViewModel(dependency: dependency, state: state)
        
        XCTAssert(vm.state.lastMessage == nil)
        XCTAssert(vm.state.status == .idle)
                
        let actionRelay = PublishRelay<HappyAction>()
        
        actionRelay.bind(to: vm.action)
            .disposed(by: db)
        
        func expect(_ tag: String, action: HappyAction) -> HappyState {
            var lastState: HappyState!
            
            let expectation = XCTestExpectation(description: tag)
            
            vm.state
                .drive(onNext: {
                    lastState = $0
                    
                    expectation.fulfill()
                })
                .disposed(by: db)
            
            actionRelay.accept(action)
            wait(for: [expectation], timeout: 1)
            
            return lastState
        }
        
        XCTAssertEqual(expect("wakeup", action: .wakeup),
                       HappyState(lastMessage: nil,
                                  status: .idle,
                                  games: dependency.games,
                                  fruits: dependency.fruits,
                                  count: 2))
        
        XCTAssertEqual(expect("play wow", action: .play(.wow)),
                       HappyState(lastMessage: nil,
                                  status: .playing(.wow),
                                  games: dependency.games,
                                  fruits: dependency.fruits,
                                  count: 3))
        
        XCTAssertEqual(expect("eat cherry", action: .eat(.cherry)),
                       HappyState(lastMessage: nil,
                                  status: .eating(.cherry),
                                  games: dependency.games,
                                  fruits: dependency.fruits,
                                  count: 4))
        
        XCTAssertEqual(expect("eat apple", action: .eat(.apple)),
                       HappyState(lastMessage: nil,
                                  status: .eating(.apple),
                                  games: dependency.games,
                                  fruits: dependency.fruits,
                                  count: 5))
        
        let message_rock = "I wanna ROCK !"
        
        
        XCTAssertEqual(expect("shout rock", action: .shout(message_rock)),
                       HappyState(lastMessage: message_rock,
                                  status: .eating(.apple),
                                  games: dependency.games,
                                  fruits: dependency.fruits,
                                  count: 6))
        
        XCTAssertEqual(expect("shout rock", action: .shout(message_rock)),
                       HappyState(lastMessage: message_rock,
                                  status: .eating(.apple),
                                  games: dependency.games,
                                  fruits: dependency.fruits,
                                  count: 7))
    }

    func test_driving_state() throws {
        var db = DisposeBag()
        
        let dependency = Dependency(games: [.lol, .wow], fruits: [.apple, .cherry])
        let state = DrivingHappyState(lastMessage: nil,
                                      status: .idle,
                                      games: [.lol],
                                      fruits: [.apple])
        let vm = DrivingStateViewModel(dependency: dependency, state: state)
        
        XCTAssert(vm.state.lastMessage == nil)
        XCTAssert(vm.state.status == .idle)

        let actionRelay = PublishRelay<HappyAction>()

        actionRelay.bind(to: vm.action)
            .disposed(by: db)

        actionRelay.accept(.wakeup)
        XCTAssert(vm.state.games == dependency.games)
        XCTAssert(vm.state.fruits == dependency.fruits)
        XCTAssertEqual(vm.state.count, 2 /* status, ready */)

        actionRelay.accept(.play(.wow))
        XCTAssert(vm.state.status == .playing(.wow))
        XCTAssertEqual(vm.state.count, 3)

        actionRelay.accept(.eat(.cherry))
        XCTAssert(vm.state.status == .eating(.cherry))
        XCTAssertEqual(vm.state.count, 4)

        actionRelay.accept(.eat(.apple))
        XCTAssert(vm.state.status == .eating(.apple))
        XCTAssertEqual(vm.state.count, 5)

        let message_rock = "I wanna ROCK !"

        actionRelay.accept(.shout(message_rock))
        XCTAssert(vm.state.lastMessage == message_rock)
        XCTAssertEqual(vm.state.count, 6)

        db = DisposeBag()

        let message_hear = "You hear me?"

        actionRelay.accept(.shout(message_hear))

        XCTAssert(vm.state.lastMessage != message_hear)
        XCTAssert(vm.state.lastMessage == message_rock)
        XCTAssertEqual(vm.state.count, 6)

        actionRelay.bind(to: vm.action)
            .disposed(by: db)

        actionRelay.accept(.shout(message_hear))

        XCTAssert(vm.state.lastMessage == message_hear)
        XCTAssertEqual(vm.state.count, 7)
        
        XCTAssertEqual(vm.$state,
                       DrivingHappyState(lastMessage: message_hear,
                                         status: .eating(.apple),
                                         games: dependency.games,
                                         fruits: dependency.fruits,
                                         count: 7))
    }
    
    func test_driving_state_drive() throws {
        let db = DisposeBag()
        
        let dependency = Dependency(games: [.lol, .wow], fruits: [.apple, .cherry])
        let state = DrivingHappyState(lastMessage: nil,
                                      status: .idle,
                                      games: [],
                                      fruits: [])
        let vm = DrivingStateViewModel(dependency: dependency, state: state)
        let actionRelay = PublishRelay<HappyAction>()
        
        actionRelay.bind(to: vm.action)
            .disposed(by: db)
        
        XCTAssertEqual(vm.$state,
                       DrivingHappyState(lastMessage: nil,
                                         status: .idle,
                                         games: [],
                                         fruits: [],
                                         count: 0))
        
        let status = XCTestExpectation(description: "status")
        let games = XCTestExpectation(description: "games")
        
        actionRelay.accept(.play(.sc))
        actionRelay.accept(.wakeup)
        
        vm.state
            .drive(onNext: {
                if $0.status == .idle {
                    status.fulfill()
                }
                if $0.games == dependency.games {
                    games.fulfill()
                }
            })
            .disposed(by: db)
        
        wait(for: [status, games], timeout: 3)
    }
    
    func test_driving_state_prop_drive() throws {
        let db = DisposeBag()
        
        let dependency = Dependency(games: [.lol, .wow], fruits: [.apple, .cherry])
        let state = DrivingHappyState(lastMessage: nil,
                                      status: .idle,
                                      games: [],
                                      fruits: [])
        let vm = DrivingStateViewModel(dependency: dependency, state: state)
        let actionRelay = PublishRelay<HappyAction>()
        
        actionRelay.bind(to: vm.action)
            .disposed(by: db)
        
        XCTAssertEqual(vm.$state,
                       DrivingHappyState(lastMessage: nil,
                                         status: .idle,
                                         games: [],
                                         fruits: [],
                                         count: 0))
        
        let status = XCTestExpectation(description: "status")
        let games = XCTestExpectation(description: "games")
        
        actionRelay.accept(.play(.sc))
        
        vm.state.$status
            .drive(onNext: {
                if $0 == .playing(.sc) {
                    status.fulfill()
                }
            })
            .disposed(by: db)
        
        actionRelay.accept(.wakeup)
        
        vm.state.$games
            .drive(onNext: {
                if $0 == dependency.games {
                    games.fulfill()
                }
            })
            .disposed(by: db)
        
        wait(for: [status, games], timeout: 3)
    }
    
    func test_driving_state_event() throws {
        let db = DisposeBag()
        
        let dependency = Dependency(games: [.lol, .wow], fruits: [.apple, .cherry])
        let state = DrivingHappyState(lastMessage: nil,
                                      status: .idle,
                                      games: [],
                                      fruits: [])
        let vm = DrivingStateViewModel(dependency: dependency, state: state)
        let actionRelay = PublishRelay<HappyAction>()
        
        actionRelay.bind(to: vm.action)
            .disposed(by: db)

        let event = XCTestExpectation(description: "event")
        vm.event
            .emit(onNext: {
                XCTAssertEqual($0, .win(.sc))
                
                event.fulfill()
            })
            .disposed(by: db)
        
        actionRelay.accept(.play(.sc))
        
        wait(for: [event], timeout: 5)
    }
    
    func test_action_by_reaction() throws {
        var rawActionHistory: [HappyAction] = []
        
        // nontyped logger
        let rawActionLogger: Middleware<HappyState, HappyAction> = nontyped_middleware { state, next, action in
            rawActionHistory.append(action)
            return next(action)
        }
        
        let dependency = Dependency(games: [.lol, .wow],
                                    fruits: [.apple, .cherry])
        let db = DisposeBag()
        let vm = StateViewModel(dependency: dependency,
                                state: HappyState(),
                                actionMiddlewares: [rawActionLogger])
        let actionRelay = PublishRelay<HappyAction>()
        
        actionRelay.bind(to: vm.action)
            .disposed(by: db)
        
        XCTAssertEqual(vm.state.status, .idle)
        
        actionRelay.accept(.sleep(3))
        
        XCTAssertEqual(rawActionHistory.last, .sleep(3))
        XCTAssertEqual(vm.state.status, .sleeping)
        
        _ = XCTWaiter.wait(for: [XCTestExpectation(description: "wakeup")], timeout: 4.0)
        
        XCTAssertEqual(rawActionHistory.last, .wakeup)
        XCTAssertEqual(vm.state.status, .idle)
        XCTAssertEqual(vm.state.games, dependency.games)
        XCTAssertEqual(vm.state.fruits, dependency.fruits)
    }
    
    func test_action_logger() throws {
        var rawActionHistory: [HappyAction] = []
        
        // nontyped logger
        let rawActionLogger: Middleware<HappyState, HappyAction> = nontyped_middleware { state, next, action in
            rawActionHistory.append(action)
            return next(action)
        }
                
        let MSG_WAKEUP = "NO"
        let MSG_PLAY = "I'm Hungry"
        let MSG_EAT = "I'm FULL"
        let MSG_SHOUT = "RAW SHOUT"
        
        // typed logger
        let actionTransformer = StateViewModel.middleware.action { state, next, action in
            switch action {
            case .wakeup:
                return next(.shout(MSG_WAKEUP))
            case .play:
                return next(.shout(MSG_PLAY))
            case .eat:
                return next(.shout(MSG_EAT))
            case .shout(let msg):
                return next(.shout(msg))
            case .sleep(let seconds):
                return next(.sleep(seconds))
            }
        }
        
        let dependency = Dependency(games: [.lol, .wow],
                                    fruits: [.apple, .cherry])
        let db = DisposeBag()
        let vm = StateViewModel(dependency: dependency,
                                state: HappyState(),
                                actionMiddlewares: [rawActionLogger, actionTransformer])
        let actionRelay = PublishRelay<HappyAction>()
        
        actionRelay.bind(to: vm.action)
            .disposed(by: db)
        
        XCTAssertEqual(vm.state.status, .idle)
        
        actionRelay.accept(.wakeup)
        
        XCTAssertEqual(rawActionHistory.last, .wakeup)
        XCTAssertEqual(vm.state.status, .idle)
        XCTAssertEqual(vm.state.lastMessage, MSG_WAKEUP)
        
        actionRelay.accept(.play(.lol))
        
        XCTAssertEqual(rawActionHistory.last, .play(.lol))
        XCTAssertEqual(vm.state.status, .idle)
        XCTAssertEqual(vm.state.lastMessage, MSG_PLAY)
        
        actionRelay.accept(.shout(MSG_SHOUT))
        
        XCTAssertEqual(rawActionHistory.last, .shout(MSG_SHOUT))
        XCTAssertEqual(vm.state.status, .idle)
        XCTAssertEqual(vm.state.lastMessage, MSG_SHOUT)
    }
    
    func test_action_ignore_logger() throws {
        var rawActionHistory: [HappyAction] = []
        
        // nontyped logger
        let rawActionLogger: Middleware<HappyState, HappyAction> = nontyped_middleware { state, next, action in
            rawActionHistory.append(action)
            return next(action)
        }
        
        // typed logger
        let actionIgnoring = StateViewModel.middleware.action { state, next, action in
            // dose not call next(action)
            return action
        }
        
        let dependency = Dependency(games: [.lol, .wow],
                                    fruits: [.apple, .cherry])
        let state = HappyState()
        
        let db = DisposeBag()
        let vm = StateViewModel(dependency: dependency,
                                state: state,
                                actionMiddlewares: [rawActionLogger, actionIgnoring])
        let actionRelay = PublishRelay<HappyAction>()
        
        actionRelay.bind(to: vm.action)
            .disposed(by: db)
        
        XCTAssertEqual(vm.state.status, .idle)
        
        actionRelay.accept(.wakeup)
        
        XCTAssertEqual(rawActionHistory.last, .wakeup)
        XCTAssertEqual(vm.$state, state)
        
        actionRelay.accept(.play(.lol))
        
        XCTAssertEqual(rawActionHistory.last, .play(.lol))
        XCTAssertEqual(vm.$state, state)
        
        actionRelay.accept(.shout("HAH"))
        
        XCTAssertEqual(rawActionHistory.last, .shout("HAH"))
        XCTAssertEqual(vm.$state, state)
    }
    
    func test_mutation_logger() throws {
        var rawMutationHistory: [HappyMutation] = []
        
        // nontyped logger
        let rawMutationLogger: Middleware<HappyState, HappyMutation> = nontyped_middleware { state, next, mutation in
            rawMutationHistory.append(mutation)
            return next(mutation)
        }
                
        let MSG_OTHER = "I'm not ready"
        let MSG_SHOUT = "shooooout"
        
        // typed logger
        let mutationTransformer = StateViewModel.middleware.mutation { state, next, mutation in
            switch mutation {
            case .lastMessage:
                return next(mutation)
            default:
                return next(.lastMessage(MSG_OTHER))
            }
        }
        
        let dependency = Dependency(games: [.lol, .wow],
                                    fruits: [.apple, .cherry])
        let db = DisposeBag()
        let vm = StateViewModel(dependency: dependency,
                                state: HappyState(),
                                mutationMiddlewares: [rawMutationLogger, mutationTransformer])
        let actionRelay = PublishRelay<HappyAction>()
        
        actionRelay.bind(to: vm.action)
            .disposed(by: db)
        
        XCTAssertEqual(vm.state.status, .idle)
        
        actionRelay.accept(.wakeup)
        
        XCTAssertEqual(rawMutationHistory.last, .ready(dependency.games, dependency.fruits))
        XCTAssertEqual(vm.state.status, .idle)
        XCTAssertEqual(vm.state.lastMessage, MSG_OTHER)
        
        actionRelay.accept(.play(.lol))
        
        XCTAssertEqual(rawMutationHistory.last, .status(.playing(.lol)))
        XCTAssertEqual(vm.state.status, .idle)
        XCTAssertEqual(vm.state.lastMessage, MSG_OTHER)
        
        actionRelay.accept(.shout(MSG_SHOUT))
        
        XCTAssertEqual(rawMutationHistory.last, .lastMessage(MSG_SHOUT))
        XCTAssertEqual(vm.state.status, .idle)
        XCTAssertEqual(vm.state.lastMessage, MSG_SHOUT)
    }
    
    func test_mutation_error() throws {
        let db = DisposeBag()
        let vm = ErrorViewModel()
        
        let actionRelay = PublishRelay<HappyAction>()
        
        actionRelay.bind(to: vm.action)
            .disposed(by: db)
        
        let expectation = XCTestExpectation(description: "error")
        
        vm.error
            .emit(onNext: { _ in
                expectation.fulfill()
            })
            .disposed(by: db)
        
        actionRelay.accept(.wakeup)
        
        wait(for: [expectation], timeout: 1)
    }
    
    func test_transform_mutation() throws {
        let db = DisposeBag()
        let vm = DelegatingViewModel()
        
        let actionRelay = PublishRelay<HappyAction>()
        
        actionRelay.bind(to: vm.action)
            .disposed(by: db)
        
        let expectation = XCTestExpectation(description: "transform_mutation")
        
        XCTAssertEqual(vm.state.status, HappyStatus.idle)
        XCTAssertEqual(vm.state.count, 0)
        XCTAssertNil(vm.state.lastMessage)
        
        actionRelay.accept(.wakeup)
        actionRelay.accept(.shout("no no"))
        
        _ = XCTWaiter.wait(for: [expectation], timeout: 1.0)
        
        XCTAssertEqual(vm.state.status, HappyStatus.sleeping)
        XCTAssertEqual(vm.state.count, 1)
        XCTAssertNil(vm.state.lastMessage)
    }
}
