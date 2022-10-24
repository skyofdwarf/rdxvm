//
//  TestTypes.swift
//  RDXVMTests
//
//  Created by YEONGJUNG KIM on 2022/01/14.
//

import Foundation
@testable import RDXVM

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
    case sleeping
}

// Action
enum HappyAction: Equatable {
    case wakeup
    case sleep(Int)
    case play(Game)
    case eat(Fruit)
    case shout(String)
}

// Mutation
enum HappyMutation: Equatable {
    case ready([Game], [Fruit])
    case status(HappyStatus)
    case lastMessage(String?)
}

// Event
enum HappyEvent: Equatable {
    case lotto
    case win(Game)
}

// Value State

struct HappyState: Equatable {
    var lastMessage: String?
    var status: HappyStatus = .idle
    
    var games: [Game] = []
    var fruits: [Fruit] = []
    
    var count: Int = 0
}

// Reference State
struct DrivingHappyState: Equatable {
    @Drived var lastMessage: String?
    @Drived var status: HappyStatus = .idle
    
    @Drived var games: [Game] = []
    @Drived var fruits: [Fruit] = []
    
    @Drived var count: Int = 0
    
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
        STATE(\(count)): \(String(describing: lastMessage)), \(status), \(games), \(fruits)
        """
    }
}
