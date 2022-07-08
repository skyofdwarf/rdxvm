//
//  Observable+Extensions.swift
//  RDXVMTests
//
//  Created by YEONGJUNG KIM on 2022/01/16.
//

import Foundation
import RxSwift

extension Observable {
    func with(interval: RxTimeInterval) -> Observable {
        return enumerated()
            .concatMap { index, element in
                Observable
                    .just(element)
                    .delay(index == 0 ? RxTimeInterval.seconds(0) : interval,
                           scheduler: MainScheduler.instance)
            }
    }
}
