//
//  RandomgDogViewController.swift
//  Reduxift_Example
//
//  Created by skyofdwarf on 2019. 1. 30..
//  Copyright © 2019년 CocoaPods. All rights reserved.
//

import UIKit
import Reduxift

struct RandomDogState: ReduxiftState {
    var imageUrl: String = ""
    var alert: String = ""
}

enum RandomDogAction: ReduxiftAction {
    case fetch(breed: String?)
    case reload(url: String)
    case alert(String)
}

extension RandomDogAction {
    var payload: Any? {
        switch self {
        case let .fetch(breed):
            return async { (dispatch) in
                let urlString = ((breed == nil) ?
                    "https://dog.ceo/api/breeds/image/random":
                    "https://dog.ceo/api/breed/\(breed!)/images/random")
                
                
                guard let url = URL(string: urlString) else {
                    _ = dispatch(.alert("failed to create a url of random dog for breed: \(breed ?? "no brred")"))
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
                    
                    if let imageUrl = json.message as Any? as? String {
                        print("image url: \(imageUrl)")
                        _ = dispatch(.reload(url: imageUrl))
                    }
                    else {
                        print("no image url")
                        _ = dispatch(.alert("no image url"))
                    }
                })
                
                task.resume()
                
                return {
                    task.cancel()
                    
                    _ = dispatch(.alert("fetching cancelled"))
                }
            }
            
        case let .reload(url):
            return url
            
        case let .alert(msg):
            return msg;
        }
    }
}



class RandomDogViewController: UIViewController {
    @IBOutlet weak var dogImageView: UIImageView!
    lazy var store: ReduxiftStore<RandomDogState> = createStore()
    var canceller: ReduxiftAction.AsyncCanceller?
    
    var breed: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        let cancelButton = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(RandomDogViewController.cancelButtonDidClick))
        let reloadButton = UIBarButtonItem(title: "Reload", style: .plain, target: self, action: #selector(RandomDogViewController.reloadButtonDidClick))
        
        self.navigationItem.rightBarButtonItems = [ reloadButton, cancelButton ]
        
        self.store.subscribe(self)
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
        self.canceller?()
    }
    
    @objc func reloadButtonDidClick(_ sender: Any?) {
        self.reload()
    }
    
    func reload() {
        self.canceller = self.store.dispatch(RandomDogAction.fetch(breed: self.breed)) as? ReduxiftAction.AsyncCanceller
    }
}

extension RandomDogViewController {
    func createStore() -> ReduxiftStore<RandomDogState> {
        let reducer: ReduxiftStore<RandomDogState>.Reducer = { (state, action) in
            var state = state
            guard let action = action as? RandomDogAction else {
                return state
            }
            
            switch action {
            case let .reload(url):
                state.imageUrl = url
            case let .alert(msg):
                state.alert = msg
            default:
                return state
            }
            return state
        }
        return ReduxiftStore<RandomDogState>(state: RandomDogState(),
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

extension RandomDogViewController: ReduxiftStoreSubscriber {
    func store(didChangeState state: ReduxiftState, action: ReduxiftAction) {
        guard let state = state as? RandomDogState else {
            return
        }
        
        if let alert = state.alert as Any? as? String, !alert.isEmpty {
            self.alert(alert)
        }
        
        if let imageUrl = state.imageUrl as? String, !imageUrl.isEmpty {
            // NOTE: Data(contentsOf:) blocks main thread while downloading.
            if let url = URL(string: imageUrl), let data = try? Data(contentsOf: url) {
                self.dogImageView.image = UIImage(data: data)
            }
        }
    }
}
