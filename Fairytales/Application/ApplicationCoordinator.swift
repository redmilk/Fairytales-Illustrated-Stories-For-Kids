//
//  ApplicationCoordinator.swift
//  AirPrint
//
//  Created by Danyl Timofeyev on 18.11.2021.
//

import Foundation
import UIKit.UIWindow
import UIKit.UINavigationController

final class ApplicationCoordinator: Coordinatable, UserSessionServiceProvidable {
    
    unowned let window: UIWindow
    var navigationController: UINavigationController?
    var childCoordinators: [Coordinatable] = []
    
    init(window: UIWindow) {
        self.window = window
    }
    
    func start() {
        /// we fetch from somewhere if it's user's first app launch
        let shouldShowOnboarding: Bool = OnboardingManager.shared?.shouldShowOnboarding ?? true
        shouldShowOnboarding ? showOnboarding() : showContent()
    }
    func end() { }
        
    private func showOnboarding() {
        OnboardingManager.shared?.onboardingFinishAction = { [weak self] in
            self?.childCoordinators.removeAll()
            self?.showContent()
            OnboardingManager.shared?.shouldShowOnboarding = false
            PurchesService.shouldDisplaySubscriptionsForCurrentUser = true
            OnboardingManager.shared = nil
        }
        let coordinator = OnboardingCoordinator(window: self.window)
        childCoordinators.append(coordinator)
        coordinator.start()
    }
    
    private func showContent() {
        navigationController = UINavigationController()
        window.rootViewController = navigationController
        window.makeKeyAndVisible()
        let coordinator = CategoriesCoordinator(navigationController: navigationController!)
        coordinator.start()
    }
}
