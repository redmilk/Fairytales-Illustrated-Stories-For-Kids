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
    
    init(navigationController: UINavigationController?) {
        self.navigationController = navigationController
    }
    deinit {
        Logger.log(String(describing: self), type: .deinited)
    }
    
    func start() {
        let controller = SettingsViewController(coordinator: self)
        navigationController?.pushViewController(controller, animated: true)
    }
    
    func end() {
        navigationController?.popViewController(animated: true)
    }
}
