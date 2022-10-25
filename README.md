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

ViewModel needs custom types for action, mutation, event, and state to subclass and create an instance.

```swift
enum Action {
    case add(Int)
    case subtract(Int)
}
enum Mutation {
    case add(Int)
    case calculating(Bool)
}
enum Event {
    case notSupported
}
struct State {
    var sum = 0
    var calculating = false
}
```

You can subclass ViewModel with these types and must override `react(action:state:)` and `reduce(mutation:state:)` methods.
In `react(action:state:`, you should return an observable of Reaction:
- a mutation to mutate state as the result of an action
- an event to notify some event to view
- an error that is explicit/implicit thrown
- an action that is mapped from another action.

```swift
class CalcViewModel: ViewModel<Action, Mutation, State, Event> {
    init(state: State = State()) {
        super.init(state: state)
    }

    override func react(action: Action, state: State) -> Observable<Reaction> {
        switch action {
        case .add(let num):
            return .of(.mutation(.calculating(true)),
                .mutation(.add(num)),
                .mutation(.calculating(false)))
        case .subtract:
            return .just(.event(.notSupported))
        }
    }

    override func reduce(mutation: Mutation, state: State) -> State {
        var state = state
        switch mutation {
        case let .add(let num):
            state.sum += num
        case let .calculating(let calculating):
            state.calculating = calculating
        }
        return state
    }
}

let vm = CalcViewModel<Action, Mutation, Event, State>()
```

Send actions to ViewModel and get outputs(event, error, state) from ViewModel.

```swift
addButton.rx.tap.map { Action.add(3) }
    .bind(to: vm.action)
    .disposed(by: dbag)

vm.event
    .emit()
    .disposed(by: dbag)

vm.error
    .emit()
    .disposed(by: dbag)

vm.state
    .drive()
    .disposed(by: dbag)
```

You can get current value of the state or property of the state.

```
// current state itself
vm.$state

// current value of state's property
vm.$state.sum

// '$' can be omitted to get prperty value of the state.
vm.state.sum
```

You can apply the `@Drived` attribute to a property of state, so you can directly drive that property instead of the state itself.

```swift
struct State {
    @Drived var sum = 0
    @Drived var calculating = false
}

vm.state.$sum.drive()
vm.state.$calculating.drive()

```
## Author

skyofdwarf, skyofdwarf@gmail.com

## License

RDXVM is available under the MIT license. See the LICENSE file for more info.
