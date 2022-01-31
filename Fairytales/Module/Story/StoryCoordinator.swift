//
//  
//  StoryCoordinator.swift
//  Fairytales
//
//  Created by Danyl Timofeyev on 14.01.2022.
//
//

import Foundation
import UIKit.UINavigationController
import Combine

protocol StoryCoordinatorProtocol {
   
}

final class StoryCoordinator: Coordinatable, StoryCoordinatorProtocol {
    var navigationController: UINavigationController?
    
    init() {

    }
    deinit {
        Logger.log(String(describing: self), type: .deinited)
    }
    
    func start() {
        let viewModel = StoryViewModel(coordinator: self)
        let controller = StoryViewController(viewModel: viewModel)

    }
    
    func end() {

    }
}
