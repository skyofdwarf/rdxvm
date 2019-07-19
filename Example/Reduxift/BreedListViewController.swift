//
//  BreedListViewController.swift
//  Reduxift_Example
//
//  Created by skyofdwarf on 2019. 1. 30..
//  Copyright © 2019년 CocoaPods. All rights reserved.
//

import UIKit
import Reduxift

enum BreedListAction: Action, Doable {
    case fetch(breed: String?)
    case cancel(Canceller)
    case alert(String)

    enum Result: Reaction {
        case reload([String])
        case fetching(Canceller)
    }
}

extension BreedListAction {
    func `do`(_ dispatch: @escaping StoreDispatcher) -> Reaction {
        switch self {
        case let .fetch(breed):
            let urlString = "https://dog.ceo/api/breeds/\((breed != nil) ? breed! + "/list": "list/all")"

            guard let url = URL(string: urlString) else {
                dispatch(BreedListAction.alert("failed to create a url for breed: \(breed ?? "no brred")"))
                return Never.do
            }
            let task = URLSession.shared.dataTask(with: url, completionHandler: { (data, response, error) in
                guard error == nil else {
                    dispatch(BreedListAction.alert("failed to load breeds: \(error!)"))
                    return
                }

                guard
                    let data = data,
                    let json = try? JSONSerialization.jsonObject(with: data, options: []) as! [String: Any] else {
                        _ = dispatch(BreedListAction.alert("failed to parse json from response"))
                        return
                }

                if let breeds = json["message"] as Any? as? [String: Any] {
                    print("breeds: \(breeds)")
                    dispatch(BreedListAction.Result.reload(Array(breeds.keys)))
                }
                else {
                    print("no breeds")
                    dispatch(BreedListAction.Result.reload([]))
                }
            })

            task.resume()

            return BreedListAction.Result.fetching({ task.cancel() })

        case .cancel(let canceller):
            canceller()

        default:
            break;
        }

        return Never.do
    }
}

struct BreedListState: State {
    var breeds: [String] = []
    var shout: String = ""
    var cats: String = ""
    var alert: String = ""

    var canceller: Canceller?

    static func reduce(_ state: BreedListState, _ action: Action) -> BreedListState {
        var state = state

        switch action {
        case BreedListAction.Result.reload(let items):
            state.breeds = items
/* TODO: Add states for fetches and cancels
            state.canceller = nil
            state.cancelling = false
            state.fetching = true

        case BreedListAction.Result.fetching(let canceller):
            state.canceller = canceller
            state.cancelling = false
            state.fetching = true

        case BreedListAction.cancel:
            state.canceller = nil
            state.cancelling = true
            state.fetching = true
*/
        case BreedListAction.alert(let msg):
            state.alert = msg

        default:
            break
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

class BreedListViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    
    let store = Store(state: BreedListState(), middlewares: middlewares())

    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        let fetchButton = UIBarButtonItem(title: "Fetch",
                                          style: .plain,
                                          target: self,
                                          action: #selector(BreedListViewController.fetchButtonDidClick))

        self.navigationItem.rightBarButtonItem = fetchButton

        self.store.subscribe { [weak self] state, action in
            guard let self = self else { return }
            
            print("new state: \(state)")

            // update app by state
            if let alert = state.alert as Any? as? String, !alert.isEmpty {
                self.alert(alert)
            }

            self.tableView.reloadData()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.

        guard
            segue.identifier == "RandomDog",
            let randomDogViewController = segue.destination as? RandomDogViewController
            else { return }


        randomDogViewController.breed = store.getState().
    }
    
    @objc func fetchButtonDidClick(_ sender: Any) {
        self.store.dispatch(BreedListAction.fetch(breed: nil))
    }
}

extension BreedListViewController {
    func alert(_ msg: String) {
        let alert = UIAlertController(title: nil, message: msg, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default) { [unowned self] (actin) in
            self.store.dispatch(BreedListAction.alert(""))
        })
        
        self.present(alert, animated: true, completion: nil)
    }
}

extension BreedListViewController: UITableViewDataSource  {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let breeds = self.store.getState().breeds
        return breeds.count
    }
}

extension BreedListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "BreedCell", for: indexPath)
        
        let breeds = self.store.getState().breeds
        let breed = breeds[indexPath.row]

        cell.textLabel?.text = breed

        return cell
    }
}
