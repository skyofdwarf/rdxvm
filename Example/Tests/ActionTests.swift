//
//  ActionTests.swift
//  Reduxift_Tests
//
//  Created by skyofdwarf on 2019. 1. 30..
//  Copyright © 2019년 CocoaPods. All rights reserved.
//

import Quick
import Nimble
import Reduxift

enum TestAction: ReduxiftAction {
    case after(seconds: Int, message: String)
    case message(String)
    
    case ping(tag: String)
    case pong(tag: String)
    
    case nopayload
    
    var payload: Any? {
        switch self {
        case let .after(seconds, msg):
            return async { (dispatch) in
                var cancelled = false
                
                DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(seconds), execute: {
                    if !cancelled {
                        _ = dispatch(.message(msg))
                    }
                })
                
                return {
                    cancelled = true
                    print("cancell me")
                }
            }
            
        case let .ping(tag):
            return async { (dispatch) in
                print("ping tag: \(tag)");
                
                DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1), execute: {
                    _ = dispatch(.pong(tag: tag))
                })
                
                return nil
            }
        case let .pong(tag):
            
            return tag
        default:
            return nil
        }
    }
}

class ActionSpec: QuickSpec {
    var store: ReduxiftStore {
        let dataReducer = ReduxiftTagAction.reduce(0) { (state, action, defaults) in
            if action.tag == "data", let payload = action.payload as? Int {
                return payload
            }
            else {
                return defaults
            }
        }
        
        let logReducer = ReduxiftTagAction.reduce(tag: "log", "") { (state, action, defaults) in
            if let payload = action.payload as? String {
                return payload
            }
            else {
                return defaults
            }
        }
        
        let pongReducer = TestAction.reduce("wait a ping") { (state, action, defaults) in
            if case let .pong(tag) = action {
                return tag
            }
            else {
                return state ?? defaults
            }
        }
        
        let messageReducer = TestAction.reduce("no message") { (state, action, defaults) in
            if case let .message(msg) = action {
                return msg
            }
            else {
                return state ?? defaults
            }
        }
        
        let reducer: ReduxiftStore.Reducer = { (state, action) in
            return [ "data": dataReducer(state.data, action),
                     "depth": [ "pong": pongReducer(state.depth?.pong, action),
                                "message": messageReducer(state.depth?.message, action) ],
                     "log": logReducer(state.log, action)
            ]
        }
        return ReduxiftStore(state: [:], reducer: reducer)
    }
    
    override func spec() {
        describe("normal redux feature") {
            
            it("can do maths") {
                expect(1) == 2
            }
        }
    }
}

