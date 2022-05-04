//
//  ApplicationCoordinator.swift
//  AirPrint
//
//  Created by Danyl Timofeyev on 18.11.2021.
//

import Foundation
import UIKit.UIWindow
import UIKit.UINavigationController

final class ApplicationCoordinator: Coordinatable, UserSessionServiceProvidable, PurchesServiceProvidable {
    
    unowned let window: UIWindow
    var navigationController: UINavigationController?
    var childCoordinators: [Coordinatable] = []
    
    init(window: UIWindow) {
        self.window = window
    }
    
    func start() {
        let coordinator = LaunchAnimationCoordinator(window: window, appCoordinator: self)
        coordinator.start()
    }
    func end() { }
    
    func startFlow() {
        let shouldShowOnboarding: Bool = OnboardingManager.shared?.shouldShowOnboarding ?? true
        shouldShowOnboarding ? showOnboarding() : showContent()
        //showContent()
    }
        
    private func showOnboarding() {
        OnboardingManager.shared?.onboardingFinishAction = { [weak self] in
            self?.childCoordinators.removeAll()
            self?.showContent()
            OnboardingManager.shared?.shouldShowOnboarding = false
            PurchesService.shouldDisplaySubscriptionsForCurrentUser = true
            OnboardingManager.shared = nil
            guard let self = self else { return }
            if !self.purchases.isUserHasActiveSubscription {
                self.showSubscriptions()
            }
        }
        let coordinator = OnboardingCoordinator(window: self.window)
        childCoordinators.append(coordinator)
        coordinator.start()
    }
    
    private func showContent() {
        let coordinator = CategoriesCoordinator(window: window)
        coordinator.start()
    }
    
    private func showSubscriptions() {
        let coordinator = SubscriptionsCoordinator(whatToShow: purchases.isUserEverHadSubscription ? .weekly : .howItWorks)
        coordinator.start()
    }
}
