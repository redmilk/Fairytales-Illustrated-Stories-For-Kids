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

final class StoryCoordinator: Coordinatable, StoryCoordinatorProtocol, UserSessionServiceProvidable {
    var navigationController: UINavigationController?
    
    init(navigationController: UINavigationController?) {
        self.navigationController = navigationController
    }
    deinit {
        Logger.log(String(describing: self), type: .deinited)
    }
    
    func start() {
        let controller = StoryViewController(coordinator: self)
        navigationController?.pushViewController(controller, animated: true)
    }
    
    func end() {
        navigationController?.popViewController(animated: true)
    }
}
