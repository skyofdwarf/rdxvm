//
//  ReduxiftTypes.swift
//  SwiftTest
//
//  Created by skyofdwarf on 2019. 1. 26..
//  Copyright © 2019년 dwarfini. All rights reserved.
//

import Foundation



/// common dispatcher type
public typealias ReduxiftDispatcher = (_ action: ReduxiftAction) -> Any


/// protocol to use dynamic member lookup on Dictionary
@dynamicMemberLookup
public protocol DynamicMemberLookupDictionary {
    associatedtype Key
    associatedtype Value
    
    subscript(key: Key) -> Value? { get }
}

/// extension to use dynamic member lookup on Dictionary
public extension DynamicMemberLookupDictionary where Key == String {
    public subscript(dynamicMember member: Key) -> Value? {
        return self[member]
    }
    
    public subscript(dynamicMember member: Key) -> [Key: Value]? {
        return self[member] as? [Key: Value]
    }

}

extension Dictionary: DynamicMemberLookupDictionary where Key == String {}

extension Dictionary: ReduxiftState where Key == String {}

