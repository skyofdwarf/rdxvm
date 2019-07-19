//
//  Types.swift
//  SwiftTest
//
//  Created by skyofdwarf on 2019. 1. 26..
//  Copyright © 2019년 dwarfini. All rights reserved.
//

import Foundation

// MARK: - Common Types

public typealias StoreDispatcher = (Action) -> Void

public typealias Dispatcher = (Action) -> Action

public typealias Canceller = () -> Void

public typealias Reducer<StateType: State> = (_ state: StateType, _ action: Action) -> StateType
