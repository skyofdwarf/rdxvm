//
//  BreedListViewController.swift
//  Reduxift_Example
//
//  Created by skyofdwarf on 2019. 1. 30..
//  Copyright © 2019년 CocoaPods. All rights reserved.
//

import UIKit
import Reduxift

extension String: Error {

}

enum BreedListAction: Action, Doable {
    enum Fetch: Action, Doable {
        case start(breed: String?)
        case cancel(Canceller)

        enum Output: Reaction {
            case response(Result<[String], Error>)
            case fetching(Canceller)
        }
    }

    enum Alert: Action {
        case hide
    }
}

extension BreedListAction.Fetch {
    func `do`(_ dispatch: @escaping StoreDispatcher) -> Reaction {
        switch self {
        case let .start(breed):
            let urlString = "https://dog.ceo/api/breeds/\((breed != nil) ? breed! + "/list": "list/all")"

            guard let url = URL(string: urlString) else {
                dispatch(Output.response(.failure("failed to create a url for breed: \(breed ?? "no brred")")))
                return Never.do
            }
            let task = URLSession.shared.dataTask(with: url, completionHandler: { (data, response, error) in
                guard error == nil else {
                    dispatch(Output.response(.failure("failed to load breeds: \(error!)")))
                    return
                }

                guard
                    let data = data,
                    let json = try? JSONSerialization.jsonObject(with: data, options: []) as! [String: Any] else {
                        _ = dispatch(Output.response(.failure("failed to parse json from response")))
                        return
                }

                if let breeds = json["message"] as Any? as? [String: Any] {
                    print("breeds: \(breeds)")
                    dispatch(Output.response(.success(Array(breeds.keys))))
                }
                else {
                    print("no breeds")
                    dispatch(Output.response(.success([])))
                }
            })

            task.resume()

            return Output.fetching({ task.cancel() })

        case .cancel(let canceller):
            canceller()
            return self
        }
    }
}

struct BreedListState: State {
    var fetching: Bool = false
    var cancelling: Bool = false

    var breeds: [String] = []
    var alert: String?

    var canceller: Canceller?

    static func reduce(_ state: BreedListState, _ action: Action) -> BreedListState {
        var state = state

        switch action {
        case BreedListAction.Fetch.Output.response(let result):
            switch result {
            case .success(let items):
                state.breeds = items
                state.canceller = nil
                state.cancelling = false
                state.fetching = false
            case .failure(let error):
                state.breeds = []
                state.canceller = nil
                state.cancelling = false
                state.fetching = false
                state.alert = error.localizedDescription
            }

        case BreedListAction.Fetch.Output.fetching(let canceller):
            state.canceller = canceller
            state.cancelling = false
            state.fetching = true

        case BreedListAction.Fetch.cancel:
            state.canceller = nil
            state.cancelling = true
            state.fetching = false

        case BreedListAction.Alert.hide:
            state.alert = nil

        default:
            break
        }
        return state
    }
}

class BreedListViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var indicatorView: UIActivityIndicatorView!

    let store = Store(state: BreedListState(), middlewares: middlewares())

    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        let fetchButton = UIBarButtonItem(title: "Fetch",
                                          style: .plain,
                                          target: self,
                                          action: #selector(BreedListViewController.fetchButtonDidClick))

        let cancelButton = UIBarButtonItem(title: "Cancel",
                                           style: .plain,
                                           target: self,
                                           action: #selector(BreedListViewController.cancelButtonDidClick))

        self.navigationItem.rightBarButtonItem = fetchButton
        self.navigationItem.leftBarButtonItem = cancelButton

        self.store.subscribe { [weak self] state, action in
            guard let self = self else { return }

            switch action {
            case BreedListAction.Fetch.Output.response(let result):
                switch result {
                case .success:
                    self.tableView.reloadData()
                case .failure(let error):
                    self.alert(error.localizedDescription)
                }

                self.indicatorView.stopAnimating()

            case BreedListAction.Fetch.Output.fetching:
                self.indicatorView.startAnimating()

            default:
                break
            }
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
            let randomDogViewController = segue.destination as? RandomDogViewController,
            let breed = sender as? String
            else { return }

        randomDogViewController.breed = breed
    }
    
    @objc func fetchButtonDidClick(_ sender: Any) {
        self.store.dispatch(BreedListAction.Fetch.start(breed: nil))
    }

    @objc func cancelButtonDidClick(_ sender: Any) {
        guard let canceller = store.getState().canceller else {
            return
        }
        self.store.dispatch(BreedListAction.Fetch.cancel(canceller))
    }
}

extension BreedListViewController {
    func alert(_ msg: String) {
        let alert = UIAlertController(title: nil, message: msg, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default) { [unowned self] (actin) in
            self.store.dispatch(BreedListAction.Alert.hide)
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

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard
            let cell = tableView.cellForRow(at: indexPath),
            let breed = cell.textLabel
            else { return }

        performSegue(withIdentifier: "RandomDog", sender: breed)
    }
}
