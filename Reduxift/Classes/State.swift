//
//  State.swift
//  Reduxift
//
//  Created by skyofdwarf on 2019. 2. 1..
//

import Foundation


/// state protocol
public protocol State {
    /// default initialization
    init()
    
}

extension State {
    public typealias Reducer = (_ state: Self, _ action: Action) -> Self
    
    public static func reduce(_ reducer: @escaping Reducer) -> Reducer {
        return reducer
    }
}

