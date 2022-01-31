//
//  
//  SettingsCoordinator.swift
//  Fairytales
//
//  Created by Danyl Timofeyev on 14.01.2022.
//
//

import Foundation
import UIKit.UINavigationController
import Combine

protocol SettingsCoordinatorProtocol {
   
}

final class SettingsCoordinator: Coordinatable, SettingsCoordinatorProtocol {
    var navigationController: UINavigationController?
    
    init() {

    }
    deinit {
        Logger.log(String(describing: self), type: .deinited)
    }
    
    func start() {
        let viewModel = SettingsViewModel(coordinator: self)
        let controller = SettingsViewController(viewModel: viewModel)

    }
    
    func end() {

    }
}
