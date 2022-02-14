//
//  Scheduler.swift
//  Fairytales
//
//  Created by Danyl Timofeyev on 11.02.2022.
//

import Foundation

final class Scheduler {

    static var backgroundWorkScheduler: OperationQueue = {
        let operationQueue = OperationQueue()
        operationQueue.maxConcurrentOperationCount = 5
        operationQueue.qualityOfService = QualityOfService.userInitiated
        return operationQueue
    }()

    static let runLoop = RunLoop.main
    static let main = DispatchQueue.main

}
