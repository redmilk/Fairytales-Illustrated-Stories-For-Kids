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
    
    init(navigationController: UINavigationController?) {
        self.navigationController = navigationController
    }
    deinit {
        Logger.log(String(describing: self), type: .deinited)
    }
    
    func start() {
        let viewModel = CategoriesViewModel(coordinator: self)
        let controller = CategoriesViewController(viewModel: viewModel)
        navigationController?.pushViewController(controller, animated: true)
    }
    
    func end() {

    }
}
