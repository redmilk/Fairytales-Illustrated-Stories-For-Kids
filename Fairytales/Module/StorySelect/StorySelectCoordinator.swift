//
//  
//  StorySelectCoordinator.swift
//  Fairytales
//
//  Created by Danyl Timofeyev on 31.01.2022.
//
//

import Foundation
import UIKit.UINavigationController
import Combine

protocol StorySelectCoordinatorProtocol {
   
}

final class StorySelectCoordinator: Coordinatable, StorySelectCoordinatorProtocol, UserSessionServiceProvidable, PurchesServiceProvidable {
    var navigationController: UINavigationController?
    
    init(navigationController: UINavigationController?) {
        self.navigationController = navigationController

    }
    deinit {
        Logger.log(String(describing: self), type: .deinited)
    }
    
    func start() {
        let controller = StorySelectViewController(coordinator: self, selectedCategory: userSession.selectedCategory)
        navigationController?.pushViewController(controller, animated: true)
    }
    
    func displaySpecialGift() {
        var whatToShow = SubscriptionsViewController.ScreenOptions.howItWorks
        if purchases.isUserHasActiveSubscription {
            whatToShow = .speciealGift
        }
        let coordinator = SubscriptionsCoordinator(whatToShow: whatToShow)
        coordinator.start()
    }
    
    func displaySelectedStory() {
        let coordinator = StoryCoordinator(navigationController: navigationController)
        coordinator.start()
    }
    
    func end() {
        navigationController?.popViewController(animated: true)
    }
}
