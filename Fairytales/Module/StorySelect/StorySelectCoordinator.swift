//
//  
//  StorySelectCoordinator.swift
//  Fairytales
//
//  Created by Danyl Timofeyev on 31.01.2022.
//
//

import Foundation
import UIKit.UINavigationController
import Combine

protocol StorySelectCoordinatorProtocol {
   
}

final class StorySelectCoordinator: Coordinatable, StorySelectCoordinatorProtocol {
    var navigationController: UINavigationController?
    
    init() {

    }
    deinit {
        Logger.log(String(describing: self), type: .deinited)
    }
    
    func start() {
        let viewModel = StorySelectViewModel(coordinator: self)
        let controller = StorySelectViewController(viewModel: viewModel)

    }
    
    func end() {

    }
}
