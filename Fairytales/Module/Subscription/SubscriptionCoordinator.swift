//
//  
//  SubscriptionCoordinator.swift
//  Fairytales
//
//  Created by Danyl Timofeyev on 14.01.2022.
//
//

import Foundation
import UIKit.UINavigationController
import Combine

protocol SubscriptionCoordinatorProtocol {
   
}

final class SubscriptionCoordinator: Coordinatable, SubscriptionCoordinatorProtocol {
    var navigationController: UINavigationController?
    
    init() {

    }
    deinit {
        Logger.log(String(describing: self), type: .deinited)
    }
    
    func start() {
        let viewModel = SubscriptionViewModel(coordinator: self)
        let controller = SubscriptionViewController(viewModel: viewModel)

    }
    
    func end() {

    }
}
