//
//  RandomgDogViewController.swift
//  Reduxift_Example
//
//  Created by skyofdwarf on 2019. 1. 30..
//  Copyright © 2019년 CocoaPods. All rights reserved.
//

import UIKit
import Reduxift


enum RandomDogAction: Action, Doable {
    case fetch(breed: String?)
    case cancel(Canceller)
    case alert(String)

    enum Result: Reaction {
        case reload(url: String)
        case fetching(Canceller)
    }
}

extension RandomDogAction {
    func `do`(_ dispatch: @escaping StoreDispatcher) -> Reaction {
        switch self {
        case .fetch(let breed):
            let urlString = ((breed == nil) ?
                "https://dog.ceo/api/breeds/image/random":
                "https://dog.ceo/api/breed/\(breed!)/images/random")

            guard let url = URL(string: urlString) else {
                dispatch(RandomDogAction.alert("failed to create a url of random dog for breed: \(breed ?? "no brred")"))
                return Never.do
            }
            let task = URLSession.shared.dataTask(with: url, completionHandler: { (data, response, error) in
                guard error == nil else {
                    dispatch(RandomDogAction.alert("failed to load breeds: \(error!)"))
                    return
                }

                guard
                    let data = data,
                    let json = try? JSONSerialization.jsonObject(with: data, options: []) as! [String: Any] else {
                        dispatch(RandomDogAction.alert("failed to parse json from response"))
                        return
                }

                if let imageUrl = json["message"] as Any? as? String {
                    print("image url: \(imageUrl)")
                    dispatch(RandomDogAction.Result.reload(url: imageUrl))
                }
                else {
                    print("no image url")
                    dispatch(RandomDogAction.alert("no image url"))
                }
            })

            task.resume()

            return RandomDogAction.Result.fetching({
                print("cancell ~~~~~~~~~")
                task.cancel()
            })

        case .cancel(let canceller):
            canceller()
            return self

        default:
            break;
        }

        return Never.do
    }
}

struct RandomDogState: State {
    var fetching: Bool = false
    var cancelling: Bool = false
    var canceller: Canceller?

    var imageUrl: String = ""
    var alert: String = ""

    static func reduce(_ state: RandomDogState, _ action: Action) -> RandomDogState {
        var state = state

        switch action {
        case RandomDogAction.Result.reload(let url):
            state.imageUrl = url

            state.canceller = nil
            state.cancelling = false
            state.fetching = true

        case RandomDogAction.Result.fetching(let canceller):
            state.canceller = canceller
            state.cancelling = false
            state.fetching = true

        case RandomDogAction.cancel:
            state.canceller = nil
            state.cancelling = true
            state.fetching = true

        case RandomDogAction.alert(let msg):
            state.alert = msg
        default:
            return state
        }
        return state
    }
}

fileprivate func middlewares<StateType: State>() -> [Middleware<StateType>] {
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

class RandomDogViewController: UIViewController {
    @IBOutlet weak var dogImageView: UIImageView!

    let store = Store(state: RandomDogState(), middlewares: middlewares())

    var breed: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        let cancelButton = UIBarButtonItem(title: "Cancel",
                                           style: .plain,
                                           target: self,
                                           action: #selector(RandomDogViewController.cancelButtonDidClick))
        let fetchButton = UIBarButtonItem(title: "Fetch",
                                          style: .plain,
                                          target: self,
                                          action: #selector(RandomDogViewController.fetchButtonDidClick))
        
        self.navigationItem.rightBarButtonItems = [ fetchButton, cancelButton ]
        
        self.store.subscribe { state, action in
            if !state.alert.isEmpty {
                self.alert(state.alert)
            }

            if !state.imageUrl.isEmpty {
                // NOTE: Data(contentsOf:) blocks main thread while downloading.
                if let url = URL(string: state.imageUrl), let data = try? Data(contentsOf: url) {
                    self.dogImageView.image = UIImage(data: data)
                }
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.reload()
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    
    @objc func cancelButtonDidClick(_ sender: Any?) {
        guard let canceller = store.getState().canceller else { return }

        store.dispatch(RandomDogAction.cancel(canceller))
    }
    
    @objc func fetchButtonDidClick(_ sender: Any?) {
        self.reload()
    }
    
    func reload() {
        store.dispatch(RandomDogAction.fetch(breed: self.breed))
    }
}

extension RandomDogViewController {
    func alert(_ msg: String) {
        let alert = UIAlertController(title: nil, message: msg, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default) { [unowned self] (actin) in
            self.store.dispatch(RandomDogAction.alert(""))
        })
        
        self.present(alert, animated: true, completion: nil)
    }
}
