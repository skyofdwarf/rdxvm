//
//  TestTypes.swift
//  ReduxiftTests
//
//  Created by YEONGJUNG KIM on 2022/01/14.
//

import Foundation
@testable import Reduxift

enum Game {
    case lol, sc, wow
}

enum Fruit {
    case apple, banana, cherry
}

enum HappyStatus: Equatable {
    case idle
    case playing(Game)
    case eating(Fruit)
}

// Action
enum HappyAction: ViewModelAction, Equatable {
    case wakeup
    case play(Game)
    case eat(Fruit)
    case shout(String)
}

// Mutation
enum HappyMutation: ViewModelMutation, Equatable {
    case ready([Game], [Fruit])
    case status(HappyStatus)
    case lastMessage(String?)
}

// Event
enum HappyEvent: ViewModelEvent, Equatable {
    case lotto
    case win(Game)
}

// Value State

struct HappyState: ViewModelState, Equatable {
    var lastMessage: String?
    var status: HappyStatus = .idle
    
    var games: [Game] = []
    var fruits: [Fruit] = []
    
    var count: Int = 0
}

// Reference State
struct DrivingHappyState: ViewModelState, Equatable {
    @Driving var lastMessage: String?
    @Driving var status: HappyStatus = .idle
    
    @Driving var games: [Game] = []
    @Driving var fruits: [Fruit] = []
    
    @Driving var count: Int = 0
    
    static func == (lhs: DrivingHappyState, rhs: DrivingHappyState) -> Bool {
        lhs.lastMessage == rhs.lastMessage &&
        lhs.status == rhs.status &&
        lhs.games == rhs.games &&
        lhs.fruits == rhs.fruits &&
        lhs.count == rhs.count
    }
}

extension DrivingHappyState: CustomDebugStringConvertible {
    var debugDescription: String {
        """
        STATE(\(count)): \(lastMessage), \(status), \(games), \(fruits)
        """
    }
}
