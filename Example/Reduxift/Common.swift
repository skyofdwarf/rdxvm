//
//  Common.swift
//  Reduxift_Example
//
//  Created by kimyj on 02/12/2019.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import Foundation
import Reduxift

func middlewares<StateType: State>() -> [Middleware<StateType>] {
    func simple_action_logger<StateType: State>(_ tag: String, action: Action, state: Store<StateType>.GetState) -> Void {
        print("[\(tag)][Action] \(action)")
    }

    func simple_state_logger<StateType: State>(_ tag: String, action: Action, state: Store<StateType>.GetState) -> Void {
        print("[\(tag)][State] \(state())")
    }

    return [ MainThreadMiddleware(),
             LogMiddleware("ACTION", simple_action_logger),
             DoableMiddleware(),
             LogMiddleware("DO REACTION", simple_action_logger),
             LazyLogMiddleware("RESULT", simple_state_logger),
    ]
}
