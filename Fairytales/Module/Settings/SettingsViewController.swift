//
//  
//  SettingsViewController.swift
//  Fairytales
//
//  Created by Danyl Timofeyev on 14.01.2022.
//
//

import UIKit
import Combine


extension SettingsViewController {
    class State: BaseState {
      
    }
}

// MARK: - StorySelectViewController

final class SettingsViewController: BaseViewController {
    enum Buttons {
        case back, heart, manageSubscription, changeName, policy, terms, share
    }
            
    @IBOutlet weak var manageSubscriptionButton: BaseButton!
    @IBOutlet weak var backButton: BaseButton!
    @IBOutlet weak var favoritesButton: BaseButton!
    @IBOutlet weak var changeNameButton: BaseButton!
    @IBOutlet weak var policyButton: BaseButton!
    @IBOutlet weak var termsOfUseButton: BaseButton!
    @IBOutlet weak var shareButton: BaseButton!
    @IBOutlet weak var sharePopoverView: UIView!
    
    private var stateValue: State { state.value as! State }

    init(coordinator: Coordinatable) {
        let initialState = State()
        super.init(coordinator: coordinator, type: Self.self, initialState: initialState)
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    deinit {
        Logger.log(String(describing: self), type: .deinited)
    }
    override func configure() {
        
    }
    override func handleEvents() {
        // buttons
        Publishers.MergeMany(
            backButton.publisher().map { _ in Buttons.back },
            favoritesButton.publisher().map { _ in Buttons.heart },
            manageSubscriptionButton.publisher().map { _ in Buttons.manageSubscription },
            changeNameButton.publisher().map { _ in Buttons.changeName },
            policyButton.publisher().map { _ in Buttons.policy },
            termsOfUseButton.publisher().map { _ in Buttons.terms },
            shareButton.publisher().map { _ in Buttons.share }
        ).sink(receiveValue: { [weak self] button in
                guard let self = self else { return }
                switch button {
                case .back: self.coordinator.end()
                case .heart: break
                case .manageSubscription:
                    let gate = ParentalGateCoordinator(navigationController: self.navigationController)
                    gate.start()
                    gate.answerResultPublisher.sink(receiveValue: { result in
                        gate.end()
                        if result {
                            (self.coordinator as? SettingsCoordinator)?.displayManageSubscription()
                        }
                    }).store(in: &self.bag)
                case .changeName:
                    (self.coordinator as? SettingsCoordinator)?.displayChangeName()
                case .policy:
                    (self.coordinator as? SettingsCoordinator)?.displayPrivacy()
                case .terms:
                    (self.coordinator as? SettingsCoordinator)?.displayTerms()
                case .share:
                    self.shareApp()
                }
            }).store(in: &bag)
    }
    
    private func shareApp() {
        let textToShare = "Check out Fairytale app"
        if let myWebsite = URL(string: "https://apps.apple.com/app/id1596570780") {
            let objectsToShare = [textToShare, myWebsite, UIImage(named: "bear-splash-1")!] as [Any]
            let activityVC = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
            /// Excluded Activities
            activityVC.excludedActivityTypes = [UIActivity.ActivityType.addToReadingList]
            if UIDevice.current.userInterfaceIdiom == .pad {
                sharePopoverView.isHidden = false
                activityVC.popoverPresentationController?.sourceView = sharePopoverView
                activityVC.popoverPresentationController?.sourceRect = sharePopoverView.frame
                activityVC.popoverPresentationController?.permittedArrowDirections = UIPopoverArrowDirection.down
                UIApplication.shared.windows.first?.rootViewController?.present(activityVC, animated: true, completion: nil)
            } else {
                self.present(activityVC, animated: true, completion: { [weak self] in
                    self?.sharePopoverView.isHidden = true
                })
            }
        }
    }
}
