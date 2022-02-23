//
//  GenderSelectCoordinator.swift
//  Fairytales
//
//  Created by Danyl Timofeyev on 21.02.2022.
//

import Foundation

protocol GenderSelectCoordinatorProtocol {
   
}

final class GenderSelectCoordinator: Coordinatable, GenderSelectCoordinatorProtocol {
    var navigationController: UINavigationController?
    
    init(navigationController: UINavigationController?) {
        self.navigationController = navigationController
    }
    deinit {
        Logger.log(String(describing: self), type: .deinited)
    }
    
    func start() {
        let controller = GenderSelectViewController(coordinator: self)
        navigationController?.pushViewController(controller, animated: true)
    }
    
    func end() {
        navigationController?.popViewController(animated: true)
    }
}
