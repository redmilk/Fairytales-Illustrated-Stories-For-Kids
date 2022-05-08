//
//  
//  ParentalGateCoordinator.swift
//  Fairytales
//
//  Created by Danyl Timofeyev on 06.05.2022.
//
//

import Foundation
import UIKit.UINavigationController
import Combine

protocol ParentalGateCoordinatable {
    func endWithAnswer(_ answer: Bool)
}

final class ParentalGateCoordinator: Coordinatable, ParentalGateCoordinatable {
    var navigationController: UINavigationController?
    var viewController: UIViewController?
    var answerResultPublisher = PassthroughSubject<Bool, Never>()
    
    init(navigationController: UINavigationController?, viewController: UIViewController? = nil) {
        self.navigationController = navigationController
        self.viewController = viewController
    }
    deinit {
        Logger.log(String(describing: self), type: .deinited)
    }
    
    func start() {
        let controller = ParentalGateViewController(coordinator: self)
        if let viewController = viewController {
            viewController.present(controller, animated: true, completion: nil)
        } else {
            navigationController?.present(controller, animated: true, completion: nil)//.pushViewController(controller, animated: true)
        }
    }
    
    func end() {
        if let viewController = viewController {
            viewController.dismiss(animated: true, completion: nil)
        } else {
            navigationController?.presentedViewController?.dismiss(animated: true, completion: nil)
        }
    }
    
    func endWithAnswer(_ answer: Bool) {
        answerResultPublisher.send(answer)
        navigationController?.presentedViewController?.dismiss(animated: true, completion: nil)
    }
}
