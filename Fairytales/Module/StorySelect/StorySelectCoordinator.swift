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
    private let isFavorites: Bool
    
    init(navigationController: UINavigationController?, isFavorites: Bool = false) {
        self.navigationController = navigationController
        self.isFavorites = isFavorites
    }
    deinit {
        Logger.log(String(describing: self), type: .deinited)
    }
    
    func start() {
        let controller = StorySelectViewController(
            coordinator: self,
            selectedCategory: isFavorites ? FirebaseClient.shared.makeFavoritesCategory() : userSession.selectedCategory,
            isFavorites: self.isFavorites)
        navigationController?.pushViewController(controller, animated: true)
    }
    
    func displaySpecialGift() {
        var whatToShow = SubscriptionsViewController.ScreenOptions.howItWorks
        if !purchases.isUserHasActiveSubscription {
            whatToShow = PurchesService.currentRandomFlag ? .specialGiftLux : .howItWorks
            print(whatToShow)
            if purchases.isUserEverHadSubscription {
                whatToShow = .specialGiftLux
            }
        }
        if purchases.isUserEverHadSubscription && !purchases.isUserHasActiveSubscription {
            whatToShow = .weekly
        }
        
        let coordinator = SubscriptionsCoordinator(whatToShow: whatToShow)
        coordinator.start()
    }
    
    func displaySelectedStory() {
        let coordinator = StoryCoordinator(navigationController: navigationController)
        coordinator.start()
    }
    
    func displaySubscriptionsPopup() {
        let coordinator = SubscriptionsCoordinator(whatToShow: .weekly)
        coordinator.start()
    }
    
    func displayFavorites() {
        let coordinator = StorySelectCoordinator(navigationController: navigationController, isFavorites: true)
        coordinator.start()
    }
    
    func end() {
        navigationController?.popViewController(animated: true)
    }
}
