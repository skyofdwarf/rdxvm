//
//  RandomgDogViewController.swift
//  Reduxift_Example
//
//  Created by skyofdwarf on 2019. 1. 30..
//  Copyright © 2019년 CocoaPods. All rights reserved.
//

import UIKit
import Reduxift


enum RandomDogAction {
    enum Fetch: Action, Doable {
        case start(breed: String?)
        case cancel(Canceller)

        enum Output: Reaction {
            case response(Result<String, Error>)
            case fetching(Canceller)
        }
    }

    enum Alert: Action {
        case hide
    }
}

extension RandomDogAction.Fetch {
    func `do`(_ dispatch: @escaping StoreDispatcher) -> Reaction {
        switch self {
        case .start(let breed):
            let urlString = ((breed == nil) ?
                "https://dog.ceo/api/breeds/image/random":
                "https://dog.ceo/api/breed/\(breed!)/images/random")

            guard let url = URL(string: urlString) else {
                dispatch(Output.response(.failure("failed to create a url of random dog for breed: \(breed ?? "no brred")")))
                return Never.do
            }
            let task = URLSession.shared.dataTask(with: url, completionHandler: { (data, response, error) in
                guard error == nil else {
                    dispatch(Output.response(.failure(error!)))
                    return
                }

                guard
                    let data = data,
                    let json = try? JSONSerialization.jsonObject(with: data, options: []) as! [String: Any] else {
                        dispatch(Output.response(.failure("failed to parse json from response")))
                        return
                }

                if let imageUrl = json["message"] as Any? as? String {
                    print("image url: \(imageUrl)")
                    dispatch(Output.response(.success(imageUrl)))
                }
                else {
                    print("no image url")
                    dispatch(Output.response(.failure("no image url")))
                }
            })

            task.resume()

            return Output.fetching({
                print("cancell ~~~~~~~~~")
                task.cancel()
            })

        case .cancel(let canceller):
            canceller()
            return self
        }
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
        case RandomDogAction.Fetch.Output.response(let result):
            switch result {
            case .success(let url):
                state.imageUrl = url
                state.canceller = nil
                state.cancelling = false
                state.fetching = false

            case .failure(let error):
                state.imageUrl = ""
                state.canceller = nil
                state.cancelling = false
                state.fetching = false
                state.alert = error.localizedDescription
            }

        case RandomDogAction.Fetch.Output.fetching(let canceller):
            state.canceller = canceller
            state.cancelling = false
            state.fetching = true

        case RandomDogAction.Fetch.cancel:
            state.canceller = nil
            state.cancelling = true
            state.fetching = false

        case RandomDogAction.Alert.hide:
            state.alert = ""

        default:
            return state
        }
        return state
    }
}

class RandomDogViewController: UIViewController {
    @IBOutlet weak var dogImageView: UIImageView!
    @IBOutlet weak var indicatorView: UIActivityIndicatorView!

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
        
        self.store.subscribe { [weak self] state, action in
            guard let self = self else { return }

            switch action {
            case RandomDogAction.Fetch.Output.response(let result):
                switch result {
                case .success(let url):
                    if let url = URL(string: url), let data = try? Data(contentsOf: url) {
                        self.dogImageView.image = UIImage(data: data)
                    }
                case .failure(let error):
                    self.alert(error.localizedDescription)
                }

                self.indicatorView.stopAnimating()

            case RandomDogAction.Fetch.Output.fetching:
                self.indicatorView.startAnimating()

            default:
                break
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

        store.dispatch(RandomDogAction.Fetch.cancel(canceller))
    }
    
    @objc func fetchButtonDidClick(_ sender: Any?) {
        self.reload()
    }
    
    func reload() {
        store.dispatch(RandomDogAction.Fetch.start(breed: self.breed))
    }
}

extension RandomDogViewController {
    func alert(_ msg: String) {
        let alert = UIAlertController(title: nil, message: msg, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default) { [unowned self] (actin) in
            self.store.dispatch(RandomDogAction.Alert.hide)
        })
        
        self.present(alert, animated: true, completion: nil)
    }
}
