//
//  
//  OnboardingCoordinator.swift
//  Fairytales
//
//  Created by Danyl Timofeyev on 14.01.2022.
//
//

import Foundation
import UIKit.UINavigationController
import Combine
import UIKit

protocol OnboardingCoordinatorProtocol {
   
}

final class OnboardingCoordinator: Coordinatable, OnboardingCoordinatorProtocol {
    var navigationController: UINavigationController?
    let window: UIWindow
    
    init(window: UIWindow) {
        self.window = window
    }
    deinit {
        Logger.log(String(describing: self), type: .deinited)
    }
    
    func start() {
        let controller = OnboardingViewController(coordinator: self)
        navigationController = UINavigationController(rootViewController: controller)
        window.rootViewController = navigationController
        window.makeKeyAndVisible()
        UIView.transition(with: window, duration: 1.5, options: [.transitionCrossDissolve], animations: { }, completion: nil)
    }
    
    func end() {

    }
}
