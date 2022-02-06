//
//  
//  CategoriesCoordinator.swift
//  Fairytales
//
//  Created by Danyl Timofeyev on 14.01.2022.
//
//

import Foundation
import UIKit.UINavigationController
import Combine

protocol CategoriesCoordinatorProtocol {
   
}

final class CategoriesCoordinator: Coordinatable, CategoriesCoordinatorProtocol {
    var navigationController: UINavigationController?
    unowned let window: UIWindow
    
    init(window: UIWindow) {
        self.window = window
    }
    deinit {
        Logger.log(String(describing: self), type: .deinited)
    }
    
    func start() {
        let controller = CategoriesViewController(coordinator: self)
        navigationController = UINavigationController(rootViewController: controller)
        window.rootViewController = navigationController
        window.makeKeyAndVisible()
        UIView.transition(with: window, duration: 1.5, options: [.transitionCrossDissolve], animations: { }, completion: nil)
    }
    
    func displaySettings() {
        let coordinator = SettingsCoordinator(navigationController: navigationController)
        coordinator.start()
    }
    
    func displayFavorites() {
        let coordinator = StorySelectCoordinator(navigationController: navigationController)
        coordinator.start()
    }
    
    func displayCategoryItems() {
        let coordinator = StorySelectCoordinator(navigationController: navigationController)
        coordinator.start()
    }
    
    func end() {

    }
}
