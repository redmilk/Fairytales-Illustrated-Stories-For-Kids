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
import CombineCocoa

extension OnboardingViewController {
    class State: BaseState {
        override init() { }
        
        var imageList: [UIImage] = [UIImage(named: "onboarding1")!,
                                    UIImage(named: "onboarding2")!,
                                    UIImage(named: "onboarding3")!,
                                    UIImage(named: "onboarding4")!,
                                    UIImage(named: "onboarding5")!,
                                    UIImage(named: "ausdfhgaskdfgk1")!,
                                    UIImage(named: "ausdfhgaskdfgk2")!,
                                    UIImage(named: "ausdfhgaskdfgk3")!,
                                    UIImage(named: "ausdfhgaskdfgk4")!,
                                    UIImage(named: "ausdfhgaskdfgk5")!,
                                    UIImage(named: "ausdfhgaskdfgk6")!,
                                    UIImage(named: "ausdfhgaskdfgk7")!,
                                    UIImage(named: "ausdfhgaskdfgk8")!,
                                    UIImage(named: "ausdfhgaskdfgk9")!,
                                    UIImage(named: "ausdfhgaskdfgk10")!]
        
        var headingList: [String] = ["Ваш ребенок в главной роли",
                                     "Возможность чтения оффлайн",
                                     "Картинки на каждой странице",
                                     "Обучайтесь и развивайтесь вместе с ребенком",
                                     "Возможность чтения в темноте",
                                     "Обучайтесь и развивайтесь вместе с ребенком",
                                     "Возможность чтения оффлайн",
                                     "Возможность чтения в темноте",
                                     "Картинки на каждой странице",
                                     "Возможность чтения оффлайн",
                                     "Картинки на каждой странице",
                                     "Возможность чтения в темноте",
                                     "Возможность чтения оффлайн",
                                     "Возможность чтения оффлайн",
                                     "Возможность чтения в темноте"]
        
        var descriptionList: [String] = ["1Lorem ipsum dolor sit amet, consectetur adipiscing elit1",
                                     "2Lorem ipsum dolor sit amet, consectetur adipiscing elit2",
                                     "3Lorem ipsum dolor sit amet, consectetur adipiscing elit3",
                                         "4Lorem ipsum dolor sit amet, consectetur adipiscing elit4",
                                         "4Lorem ipsum dolor sit amet, consectetur adipiscing elit4",
                                         "4Lorem ipsum dolor sit amet, consectetur adipiscing elit4",
                                         "4Lorem ipsum dolor sit amet, consectetur adipiscing elit4",
                                         "4Lorem ipsum dolor sit amet, consectetur adipiscing elit4",
                                         "4Lorem ipsum dolor sit amet, consectetur adipiscing elit4",
                                         "4Lorem ipsum dolor sit amet, consectetur adipiscing elit4",
                                         "4Lorem ipsum dolor sit amet, consectetur adipiscing elit4",
                                         "4Lorem ipsum dolor sit amet, consectetur adipiscing elit4",
                                         "4Lorem ipsum dolor sit amet, consectetur adipiscing elit4",
                                     "4Lorem ipsum dolor sit amet, consectetur adipiscing elit4",
                                     "5Lorem ipsum dolor sit amet, consectetur adipiscing elit5"]

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

final class OnboardingViewController: BaseViewController {
    
    @IBOutlet weak var pageControl: UIPageControl!
    @IBOutlet weak var image: UIImageView!
    @IBOutlet weak var continueButton: UIButton!
    @IBOutlet weak var skipButton: UIButton!
    @IBOutlet weak var headingLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    
    var state = CurrentValueSubject<OnboardingViewController.State, Never>(State())

    init(coordinator: Coordinatable) {
        super.init(coordinator: coordinator, type: Self.self)
    }
    required init?(coder: NSCoder) {
        //super.init(coder: coder)
        fatalError("init(coder:) has not been implemented")
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        handleState()
        continueButton.tapPublisher.map { _ in }
        .sink(receiveValue: { [weak self] in
            guard let state = self?.state.value else { return }
            state.currentImageIndex += 1
            self?.pageControl.currentPage += 1
            self?.state.value = state
        }).store(in: &bag)
        skipButton.tapPublisher.map { _ in }
        .sink(receiveValue: { [weak self] in
            guard let state = self?.state.value else { return }
            state.currentImageIndex -= 1
            self?.pageControl.currentPage -= 1
            self?.state.value = state
        }).store(in: &bag)
    }
    override func configure() {
        
    }
    override func handleEvents() {
        
    }
    override func handleState() {
        state.compactMap { $0 }
            .sink(receiveValue: { [weak self] state in
                guard let self = self else { return }
//                guard !state.shouldEndOnboarding else {
//                    return state.currentImageIndex = 0
//                }
                UIView.transition(with: self.view, duration: 0.7, options: [.transitionCrossDissolve], animations: {
                    self.image.image = state.currentImage
                }, completion: nil)
                self.headingLabel.text = state.currentImage.size.debugDescription
                self.descriptionLabel.text = state.currentImage.imageRendererFormat.debugDescription
        }).store(in: &bag)
    }
}
