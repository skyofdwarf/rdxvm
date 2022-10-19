# RDXVM

[![CI Status](https://img.shields.io/travis/skyofdwarf/rdxvm.svg?style=flat)](https://travis-ci.org/skyofdwarf/rdxvm)
[![Version](https://img.shields.io/cocoapods/v/rdxvm.svg?style=flat)](https://cocoapods.org/pods/rdxvm)
[![License](https://img.shields.io/cocoapods/l/rdxvm.svg?style=flat)](https://cocoapods.org/pods/rdxvm)
[![Platform](https://img.shields.io/cocoapods/p/rdxvm.svg?style=flat)](https://cocoapods.org/pods/rdxvm)

RDXVM is another MVVM implementation inspired by Redux and ReactorKit.

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

- Swift 5
- iOS 9

## Depencencies

- RxCocoa (~> 6.0)
- RxRelay (~> 6.0)
- RxSwift (~> 6.0)

## Installation

RDXVM is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'RDXVM'
```

## Usage

ViewModel needs some types to create an instance: action, mutation, event, and state.

```swift
// Action
enum Action {
    case play(Game)
    case eat(Fruit)
    
    struct Game {}
    struct Fruit {}
}

// Mutation
enum Mutation {
    case play(Game)
    case fruit(Fruit)
    case level(Int)
    case exp(Int)
}

// Event
enum Event {
    case alert(String)
    case levelup(Int)    
}

// State
struct State {
    var game: Game?
    var fruit: Fruit?    
    var level = 0
    var exp = 0
}
```

You can subclass ViewModel with these types and must override `react(action:state:)` and `reduce(mutation:state:)` methods.
In `react(action:state:`, you should return an observable of Reaction:
- a mutation to mutate state as the result of an action
- an event to notify some event to view
- an error that is explicit/implicit thrown
- an action that is mapped from another action.

```swift
class LifeViewModel: ViewModel<Action, Mutation, State, Event> {
    init(state: State = State()/*, some dependencies */) {
        super.init(state: state)
    }
    
    override func react(action: Action, state: State) -> Observable<Reaction> {
        switch action {
        case .play(let game):
            return .of(.mutation(.play(game)), .mutation(.exp(state.exp + 100)))
        case .eat(let fruit):
            let level = state.level + 1
            return .of(.mutations(.fruit(fruit)), .mutations(.level(level)), .event(.levelup(level)))
        }
    }
    
    override func reduce(mutation: Mutation, state: State) -> State {
        var state = state
        switch mutation {
        case let .play(let game):
            state.game = game
        case let .fruit(let fruit):
            state.fruit = fruit
        case let .level(let level):
            state.level = level
        case let .exp(let exp):
            state.exp = exp
        }        
        return state
    }
}

let vm = LifeViewModel<Action, Mutation, Event, State>()
```

Send actions to ViewModel and get outputs(event, error, state) from ViewModel.

```swift

// input: action
playButton.rx.tap.map { Action.play(Game) }
    .bind(to: vm.action)
    .disposed(by: dbag)

vm.event
    .emit()
    .disposed(by: dbag)

vm.error
    .emit()
    .disposed(by: dbag)

// drive state
vm.state
    .drive()
    .disposed(by: dbag)

// get current state
let level: Int = vm.state.level   
```

You can also drive specific property of state if you attribute that with @Driving property wrapper. 

```swift
struct OtherState {
    var game: Game?
    @Driving var level = 0
}

// drive level only
vm.state.$level
    .drive()  
```

## Author

skyofdwarf, skyofdwarf@gmail.com

## License

RDXVM is available under the MIT license. See the LICENSE file for more info.
