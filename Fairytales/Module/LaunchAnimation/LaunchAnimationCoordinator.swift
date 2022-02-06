//
//  
//  LaunchAnimationCoordinator.swift
//  Fairytales
//
//  Created by Danyl Timofeyev on 06.02.2022.
//
//

import Foundation
import UIKit.UINavigationController
import Combine

protocol LaunchAnimationCoordinatorProtocol {
   
}

final class LaunchAnimationCoordinator: Coordinatable, LaunchAnimationCoordinatorProtocol {
    var navigationController: UINavigationController?
    unowned let appcoordinator: ApplicationCoordinator
    unowned let window: UIWindow
    
    init(window: UIWindow, appCoordinator: ApplicationCoordinator) {
        self.window = window
        self.appcoordinator = appCoordinator
    }
    deinit {
        Logger.log(String(describing: self), type: .deinited)
    }
    
    func start() {
        let controller = LaunchAnimationViewController(coordinator: self)
        navigationController = UINavigationController(rootViewController: controller)
        window.rootViewController = navigationController
        window.makeKeyAndVisible()
    }
    
    func startAppFlow() {
        appcoordinator.startFlow()
    }
    
    func end() {
        
    }
}
