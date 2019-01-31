//
//  BreedListViewController.swift
//  Reduxift_Example
//
//  Created by skyofdwarf on 2019. 1. 30..
//  Copyright © 2019년 CocoaPods. All rights reserved.
//

import UIKit
import Reduxift

enum BreedListAction: ReduxiftAction {
    case fetch(breed: String?)
    case reload([String])
    case alert(String)
}

extension BreedListAction {
    var payload: Any? {
        switch self {
        case let .fetch(breed):
            return async { (dispatch) in
                let urlString = "https://dog.ceo/api/breeds/\((breed != nil) ? breed! + "/list": "list/all")"
                
                guard let url = URL(string: urlString) else {
                    _ = dispatch(.alert("failed to create a url for breed: \(breed ?? "no brred")"))
                    return nil
                }
                let task = URLSession.shared.dataTask(with: url, completionHandler: { (data, response, error) in
                    guard error == nil else {
                        _ = dispatch(.alert("failed to load breeds: \(error!)"))
                        return
                    }
                    
                    guard
                        let data = data,
                        let json = try? JSONSerialization.jsonObject(with: data, options: []) as! [String: Any] else {
                            _ = dispatch(.alert("failed to parse json from response"))
                            return
                    }
                    
                    if let status = json.status as Any? as? String {
                        print("status: \(status)")
                    }
                    
                    if let breeds = json.message as Any? as? [String: Any] {
                        print("breeds: \(breeds)")
                        _ = dispatch(.reload(Array(breeds.keys)))
                    }
                    else {
                        print("no breeds")
                        _ = dispatch(.reload([]))
                    }
                })
                
                task.resume()
                
                return {
                    task.cancel()
                    
                    print("fetching cancelled")
                }
            }
            
        case let .reload(breeds):
            return breeds
        case let .alert(msg):
            return msg;
        }
    }
}



class BreedListViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    
    lazy var store: ReduxiftDictionaryStore = createStore()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        let reloadButton = UIBarButtonItem(title: "Reload", style: .plain, target: self, action: #selector(BreedListViewController.reloadButtonDidClick))
        
        self.navigationItem.rightBarButtonItem = reloadButton
        
        self.store.subscribe(self)
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    
    @objc func reloadButtonDidClick(_ sender: Any) {
        self.store.dispatch(BreedListAction.fetch(breed: nil))
    }
}

extension BreedListViewController {
    func createStore() -> ReduxiftDictionaryStore {
        let breedsReducer = BreedListAction.reduce([]) { (state, action, defaults) in
            if case let .reload(items) = action {
                return items
            }
            else {
                return state ?? defaults
            }
        }
        
        let alertReducer = BreedListAction.reduce("") { (state, action, defaults) in
            if case let .alert(msg) = action {
                return msg
            }
            else {
                return state ?? defaults
            }
        }
        
        let reducer: ReduxiftDictionaryStore.Reducer = { (state, action) in
            return [ "description": "Reduxift Example App",
                     "data": [ "dogs": [ "breeds": breedsReducer(state.data?.dogs?.breeds, action),
                                         "shout": "bow" ],
                               "cats": "NA" ],
                     "alert": alertReducer(state.alert, action)
            ]
        }
        return ReduxiftDictionaryStore(state: [:],
                                       reducer: reducer,
                                       middlewares:[ MainQueueMiddleware(),
                                                     FunctionMiddleware({ print("log: \($1)") }),
                                                     AsyncActionMiddleware() ])
    }
    
    func alert(_ msg: String) {
        let alert = UIAlertController(title: nil, message: msg, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default))
        
        self.present(alert, animated: true, completion: nil)
    }
}

extension BreedListViewController: ReduxiftStoreSubscriber {
    typealias State = ReduxiftDictionaryState
    func store(didChangeState state: ReduxiftDictionaryState, action: ReduxiftAction) {

        // update app by state
        if let alert = state.alert as Any? as? String, !alert.isEmpty {
            self.alert(alert)
        }

        self.tableView.reloadData()
    }
}

extension BreedListViewController: UITableViewDataSource  {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let breeds = self.store.state.data?.dogs?.breeds as Any? as? [String] {
            return breeds.count
        }
        else  {
            return 0
        }
    }
}

extension BreedListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "BreedCell", for: indexPath)
        
        if let breeds = self.store.state.data?.dogs?.breeds as Any? as? [String] {
            let breed = breeds[indexPath.row]
            cell.textLabel?.text = breed
        }
        return cell
    }
}
