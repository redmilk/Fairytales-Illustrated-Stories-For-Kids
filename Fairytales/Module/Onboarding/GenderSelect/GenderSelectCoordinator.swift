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
    private let isFromSettings: Bool
    
    init(navigationController: UINavigationController?, isFromSetting: Bool = false) {
        self.navigationController = navigationController
        self.isFromSettings = isFromSetting
    }
    deinit {
        Logger.log(String(describing: self), type: .deinited)
    }
    
    func start() {
        let controller = GenderSelectViewController(coordinator: self, isFromSettings: self.isFromSettings)
        navigationController?.pushViewController(controller, animated: true)
    }
    
    func end() {
        navigationController?.popViewController(animated: true)
    }
}
