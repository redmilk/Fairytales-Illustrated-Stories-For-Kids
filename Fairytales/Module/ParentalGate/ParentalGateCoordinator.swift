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
    var answerResultPublisher = PassthroughSubject<Bool, Never>()
    
    init(navigationController: UINavigationController?) {
        self.navigationController = navigationController
    }
    deinit {
        Logger.log(String(describing: self), type: .deinited)
    }
    
    func start() {
        let controller = ParentalGateViewController(coordinator: self)
        navigationController?.present(controller, animated: true, completion: nil)//.pushViewController(controller, animated: true)
    }
    
    func end() {
        navigationController?.presentedViewController?.dismiss(animated: true, completion: nil)
    }
    
    func endWithAnswer(_ answer: Bool) {
        answerResultPublisher.send(answer)
        navigationController?.presentedViewController?.dismiss(animated: true, completion: nil)
    }
}
