//
//  
//  OnboardingViewController.swift
//  Fairytales
//
//  Created by Danyl Timofeyev on 14.01.2022.
//
//

import UIKit
import Combine

extension OnboardingViewController {
    class State: BaseState {
        override init() { } 
        
        var imageList: [UIImage] = [UIImage(named: "onboarding1")!,
                                    UIImage(named: "onboarding2")!,
                                    UIImage(named: "onboarding3")!,
                                    UIImage(named: "onboarding4")!,
                                    UIImage(named: "onboarding5")!]
        
        var headingList: [String] = ["Ваш ребенок в главной роли",
                                     "Возможность чтения оффлайн",
                                     "Картинки на каждой странице",
                                     "Обучайтесь и развивайтесь вместе с ребенком",
                                     "Возможность чтения онлайн"]
        
        var descriptionList: [String] = ["1Lorem ipsum dolor sit amet, consectetur adipiscing elit1",
                                     "2Lorem ipsum dolor sit amet, consectetur adipiscing elit2",
                                     "3Lorem ipsum dolor sit amet, 2Lorem ipsum dolor sit amet, consectetur adipiscing elit2 2Lorem ipsum dolor sit amet, consectetur adipiscing elit2 2Lorem ipsum dolor sit amet, consectetur adipiscing elit2consectetur adipiscing elit3",
                                     "4Lorem ipsum dolor sit amet, consectetur adipiscing elit4",
                                     "5Lorem ipsum dolor sit amet"]

        lazy var currentImage: UIImage = self.imageList[currentImageIndex]
        lazy var currentHeading: String = self.headingList[currentImageIndex]
        lazy var currentDescription: String = self.descriptionList[currentImageIndex]
        var shouldEndOnboarding: Bool = false
        

        var currentImageIndex = 0 {
            didSet {
                guard currentImageIndex >= 0, currentImageIndex < imageList.count else {
                    return shouldEndOnboarding = true
                }
                currentImage = imageList[currentImageIndex]
                currentHeading = headingList[currentImageIndex]
                currentDescription = descriptionList[currentImageIndex]
            }
        }
    }
}

// MARK: - OnboardingViewController

final class OnboardingViewController: BaseViewController {
    
    @IBOutlet weak var pageControl: UIPageControl!
    @IBOutlet weak var image: UIImageView!
    @IBOutlet weak var continueButton: UIButton!
    @IBOutlet weak var skipButton: UIButton!
    @IBOutlet weak var headingLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    
    var stateValue: OnboardingViewController.State { state.value as! OnboardingViewController.State }
    
    init(coordinator: OnboardingCoordinator) {
        super.init(coordinator: coordinator, type: Self.self, initialState: State())
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
  
    override func configure() {
        pageControl.preferredIndicatorImage = UIImage(named: "page-control-indicator")!
        pageControl.numberOfPages = 5
        pageControl.currentPage = 0
    }
    override func handleEvents() {
        continueButton.publisher().map { _ in }
        .sink(receiveValue: { [weak self] in
            guard let state = self?.stateValue else { return }
            if state.currentImageIndex == 3 {
                (self?.coordinator as? OnboardingCoordinator)?.displayGenderSettings()
                return
            }
            state.currentImageIndex += 1
            self?.pageControl.currentPage += 1
            self?.state.value = state
        }).store(in: &bag)
        skipButton.publisher().map { _ in }
        .sink(receiveValue: { [weak self] in
            guard let state = self?.stateValue else { return }
            state.currentImageIndex -= 1
            self?.pageControl.currentPage -= 1
            self?.state.value = state
        }).store(in: &bag)
    }
    override func handleState() {
        state.compactMap { $0 as? OnboardingViewController.State }
        .sink(receiveValue: { [weak self] state in
                guard let self = self else { return }
                guard !state.shouldEndOnboarding else {
                    OnboardingManager.shared?.onboardingFinishAction()
                    OnboardingManager.shared = nil
                    return
                }
                UIView.transition(with: self.view, duration: 0.7, options: [.transitionCrossDissolve], animations: {
                    self.image.image = state.currentImage
                }, completion: nil)
                self.headingLabel.text = state.currentHeading
                self.descriptionLabel.text = state.currentDescription
        }).store(in: &bag)
    }
  
}
