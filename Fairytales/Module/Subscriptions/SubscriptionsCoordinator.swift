//
//  
//  SubscriptionsCoordinator.swift
//  Fairytales
//
//  Created by Danyl Timofeyev on 30.03.2022.
//
//

import Foundation
import UIKit.UINavigationController
import Combine

protocol SubscriptionsCoordinatorProtocol {
   
}

final class SubscriptionsCoordinator: Coordinatable, SubscriptionsCoordinatorProtocol {
    var navigationController: UINavigationController?
    private let whatToShow: SubscriptionsViewController.ScreenOptions
    private var controller: UIViewController?
    
    init(whatToShow: SubscriptionsViewController.ScreenOptions) {
        self.whatToShow = whatToShow
    }
    deinit {
        Logger.log(String(describing: self), type: .deinited)
    }
    
    func start() {
        controller = SubscriptionsViewController(coordinator: self, whatToShow: whatToShow)
        //controller?.preferredContentSize = CGSize(width: 865, height: 370)
        controller?.modalPresentationStyle = .fullScreen
        UIViewController.topViewController?.present(controller!, animated: true, completion: nil)
    }
    
    func end() {
        controller?.dismiss(animated: true, completion: nil)
    }
}
