//
//  
//  SubscriptionsViewController.swift
//  Fairytales
//
//  Created by Danyl Timofeyev on 30.03.2022.
//
//

import UIKit
import Combine

extension SubscriptionsViewController {
    enum Purchase {
        case weekly
        case monthly
        case yearly
    }
    enum ScreenOptions {
        case howItWorks
        case weekly
        case weeklyWithDiscount
        case monthlyAndYearly
        //case speciealGift
        case specialGiftLux
    }
    
    class State: BaseState {
        var whatToShow: ScreenOptions
        var selectedPurchase: Purchase = .weekly

        init(whatToShow: ScreenOptions) {
            self.whatToShow = whatToShow
        }
    }
}

// MARK: - SubscriptionsViewController
final class SubscriptionsViewController: BaseViewController, PurchesServiceProvidable {
  
    enum Button {
        case monthly, yearly, purchase, close, renewSubscription, politics, plans, giftPurchase, giftClose
    }
    
    @IBOutlet weak var specialGiftContainer: UIView!
    @IBOutlet weak var weekSubscriptionContainer: UIView!
    @IBOutlet weak var monthAndYearSubscriptionContainer: UIView!
    //week
    @IBOutlet weak var weeklyPriceLabel: UILabel!
    @IBOutlet weak var trialDescriptionLabel: UILabel!
    // month
    @IBOutlet weak var monthlyButton: UIButton!
    @IBOutlet weak var monthlyRadioButton: UIButton!
    @IBOutlet weak var monthlyImageButton: UIButton!
    @IBOutlet weak var monthlyPriceLabel: UILabel!
    @IBOutlet weak var bottomFillerButton: UIButton!
    // yearly
    @IBOutlet weak var yearlyButton: UIButton!
    @IBOutlet weak var yearlyRadioButton: UIButton!
    @IBOutlet weak var yearlyImageButton: UIButton!
    @IBOutlet weak var yearlyPriceLabel: UILabel!
    @IBOutlet weak var yearlyCrossedPriceLabel: UILabel!
    // common
    @IBOutlet weak var continueButton: UIButton!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var rightsOfUsageButton: UIButton!
    @IBOutlet weak var renewSubscriptionButton: UIButton!
    @IBOutlet weak var politicsButton: UIButton!
    @IBOutlet weak var plansButton: UIButton!
    
    @IBOutlet weak var backgroundImageView: UIImageView!
    
    @IBOutlet weak var howItWorksDescriptionsTitleFirst: UILabel!
    @IBOutlet weak var howItWorksDescriptionsTitleSecond: UILabel!
    @IBOutlet weak var howItWorksDescriptionsTitleThird: UILabel!

    @IBOutlet weak var howItWorksDescriptionsFirst: UILabel!
    @IBOutlet weak var howItWorksDescriptionsSecond: UILabel!
    @IBOutlet weak var howItWorksDescriptionsThird: UILabel!

    @IBOutlet weak var howItWorksIcon1: UIImageView!
    @IBOutlet weak var howItWorksIcon2: UIImageView!
    @IBOutlet weak var howItWorksIcon3: UIImageView!

    // how it works
    @IBOutlet weak var howItWorksDescriptions: UIStackView!
    @IBOutlet weak var howItWorksGradientImageView: UIImageView!
    @IBOutlet weak var howItWorksTitleLabel: UILabel!
    // default descriptions
    @IBOutlet weak var defaultDescriptions: UIStackView!
    @IBOutlet weak var defaultDescriptionsGradientImageView: UIImageView!
    // special gift
    @IBOutlet weak var specialGiftPriceLabel: UILabel!
    @IBOutlet weak var specialGiftTimerLabel: UILabel!
    @IBOutlet weak var specialGiftPurchaseButton: UIButton!
    @IBOutlet weak var specialGiftCloseButton: UIButton!
    // special gift lux
    @IBOutlet weak var specialGiftLuxPriceCrossed: UILabel!
    @IBOutlet weak var specialGiftLuxPriceLabel: UILabel!
    @IBOutlet weak var specialGiftLuxContainer: UIView!
    
    private var stateValue: State { state.value as! State }
    private var continueButtonAnimCancellable: AnyCancellable?
    
    init(coordinator: Coordinatable, whatToShow: ScreenOptions) {
        let initialState = State(whatToShow: whatToShow)
        super.init(coordinator: coordinator, type: Self.self, initialState: initialState)
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    deinit {
        Logger.log(String(describing: self), type: .deinited)
    }
    
    override func configure() {
        stateValue.whatToShow = stateValue.whatToShow
        specialGiftPriceLabel.text = PurchesService.previousYearlyPrice
        weeklyPriceLabel.text = PurchesService.previousWeeklyPrice
        monthlyPriceLabel.text = PurchesService.previousMonthlyPrice
        yearlyPriceLabel.text = PurchesService.previousYearlyPrice
        yearlyCrossedPriceLabel.attributedText = purchases.getFormattedYearPriceForPurchase(isPurePrice: false, size: UIDevice.current.isIPad ? 24 : 20)
        specialGiftLuxPriceLabel.text = PurchesService.previousYearlyPrice
        specialGiftLuxPriceCrossed.attributedText = purchases.getFormattedYearPriceForPurchase(isPurePrice: false, size: UIDevice.current.isIPad ? 24 : 20)
        specialGiftContainer.isHidden = true
        
        handleWhatToShow(stateValue.whatToShow)
        purchases.output.sink(receiveValue: { [weak self] response in
            guard let self = self else { return }
            switch response {
            case .timerTick(let timerString):
                self.specialGiftTimerLabel.text = timerString
            case .loadingState(let state):
                state ? self.startActivityAnimation() : self.stopActivityAnimation()
            case .displayAlert(let text, let title, let action, let buttonTitle):
                self.displayAlert(fromParentView: self.view, with: text, title: title, action: action, buttonTitle: buttonTitle, extraAction: nil, extraActionTitle: nil)
            case .successfullyPurchased:
                (self.coordinator as? SubscriptionsCoordinator)?.end()
            case _: break
            }
        }).store(in: &bag)
    }
    
    override func handleState() {
        state.compactMap { $0 as? SubscriptionsViewController.State }
        .sink(receiveValue: { [weak self] state in
            guard let self = self else { return }
            self.handleWhatToShow(state.whatToShow)
        }).store(in: &bag)
    }
    
    override func handleEvents() {
        lifecycle.sink(receiveValue: { [weak self] lyfecycle in
            guard let self = self else { return }
            switch lyfecycle {
            case .viewDidAppear:
                self.continueButton.layer.removeAllAnimations()
                self.continueButton.dropShadow(color: .blue, opacity: 0.0, offSet: .zero, radius: 10, scale: true)
                self.continueButtonAnimCancellable?.cancel()
                self.continueButtonAnimCancellable = self.continueButton.animateBounceAndShadow()
            case _: break
            }
        }).store(in: &bag)
        
        Publishers.MergeMany(
            monthlyButton.publisher().map { _ in Button.monthly },
            yearlyButton.publisher().map { _ in Button.yearly },
            continueButton.publisher().map { _ in Button.purchase },
            closeButton.publisher().map { _ in Button.close },
            renewSubscriptionButton.publisher().map { _ in Button.renewSubscription },
            politicsButton.publisher().map { _ in Button.politics },
            plansButton.publisher().map { _ in Button.plans },
            specialGiftPurchaseButton.publisher().map { _ in Button.giftPurchase },
            specialGiftCloseButton.publisher().map { _ in Button.giftClose })
            .sink(receiveValue: { [weak self] button in
                guard let self = self else { return }
                switch button {
                case .giftClose:
                    (self.coordinator as? SubscriptionsCoordinator)?.end()
                case .close:
                    if self.stateValue.whatToShow == .monthlyAndYearly {
                        self.handleWhatToShow(.weekly)
                        self.stateValue.selectedPurchase = .weekly
                    } else {
                        (self.coordinator as? SubscriptionsCoordinator)?.end()
                    }
                case .purchase:
                    let gate = ParentalGateCoordinator(navigationController: nil, viewController: self)
                    gate.start()
                    gate.answerResultPublisher.sink(receiveValue: { result in
                        gate.end()
                        if result {
                            switch self.stateValue.selectedPurchase {
                            case .monthly: self.purchases.purchaseSubscriptionPlan(.monthly)
                            case .weekly: self.purchases.purchaseSubscriptionPlan(.weekly)
                            case .yearly: self.purchases.purchaseSubscriptionPlan(.annual)
                            }
                        }
                    }).store(in: &self.bag)
                case .giftPurchase:
                    self.purchases.purchaseSubscriptionPlan(.annual)
                case .monthly:
                    self.toggleState()
                    self.stateValue.selectedPurchase = .monthly
                case .yearly:
                    self.toggleState()
                    self.stateValue.selectedPurchase = .yearly
                case .renewSubscription:
                    let gate = ParentalGateCoordinator(navigationController: nil, viewController: self)
                    gate.start()
                    gate.answerResultPublisher.sink(receiveValue: { result in
                        gate.end()
                        if result {
                            self.purchases.restoreLastSubscription()
                        }
                    }).store(in: &self.bag)
                case .politics: break
                case .plans:
                    let state = self.stateValue
                    state.whatToShow = .monthlyAndYearly
                    state.selectedPurchase = .monthly
                    self.state.send(state)
                }
            }).store(in: &bag)
    }
    
    private func toggleState() {
        monthlyButton.isSelected.toggle()
        monthlyRadioButton.isSelected.toggle()
        monthlyImageButton.isSelected.toggle()
        yearlyButton.isSelected.toggle()
        yearlyRadioButton.isSelected.toggle()
        yearlyImageButton.isSelected.toggle()
        bottomFillerButton.isSelected.toggle()
    }
    
    private func handleWhatToShow(_ options: ScreenOptions) {
        switch options {
        case .howItWorks:
            stateValue.whatToShow = .howItWorks
            specialGiftContainer.isHidden = true
            defaultDescriptions.isHidden = true
            defaultDescriptionsGradientImageView.isHidden = true
            howItWorksDescriptions.isHidden = false
            howItWorksGradientImageView.isHidden = false
            howItWorksTitleLabel.isHidden = false
            monthAndYearSubscriptionContainer.isHidden = true
            weekSubscriptionContainer.isHidden = false
            specialGiftLuxContainer.isHidden = true
            backgroundImageView.image = UIImage(named: "subscriptions-background")
        case .weekly, .weeklyWithDiscount:
            stateValue.whatToShow = .weekly
            specialGiftContainer.isHidden = true
            defaultDescriptions.isHidden = false
            defaultDescriptionsGradientImageView.isHidden = false
            howItWorksDescriptions.isHidden = true
            howItWorksGradientImageView.isHidden = true
            howItWorksTitleLabel.isHidden = true
            monthAndYearSubscriptionContainer.isHidden = true
            weekSubscriptionContainer.isHidden = false
            plansButton.isHidden = false
            trialDescriptionLabel.isHidden = purchases.isUserEverHadSubscription
            backgroundImageView.image = UIImage(named: "subscriptions-background")
            specialGiftLuxContainer.isHidden = true
        case .monthlyAndYearly:
            stateValue.whatToShow = .monthlyAndYearly
            specialGiftContainer.isHidden = true
            defaultDescriptions.isHidden = false
            defaultDescriptionsGradientImageView.isHidden = false
            howItWorksDescriptions.isHidden = true
            howItWorksGradientImageView.isHidden = true
            howItWorksTitleLabel.isHidden = true
            monthAndYearSubscriptionContainer.isHidden = false
            weekSubscriptionContainer.isHidden = true
            plansButton.isHidden = true
            specialGiftLuxContainer.isHidden = true
            backgroundImageView.image = UIImage(named: "subscriptions-background")
//        case .speciealGift:
//            stateValue.whatToShow = .speciealGift
//            specialGiftContainer.isHidden = false
        case .specialGiftLux:
            plansButton.isHidden = true
            stateValue.whatToShow = .specialGiftLux
            specialGiftContainer.isHidden = true
            defaultDescriptions.isHidden = true
            defaultDescriptionsGradientImageView.isHidden = true
            howItWorksDescriptions.isHidden = false
            howItWorksGradientImageView.isHidden = false
            howItWorksTitleLabel.isHidden = false
            howItWorksTitleLabel.text = "В нашем специальном\nпредложении вы найдёте:"
            monthAndYearSubscriptionContainer.isHidden = true
            weekSubscriptionContainer.isHidden = true
            specialGiftLuxContainer.isHidden = false
            howItWorksDescriptionsTitleFirst.isHidden = true
            howItWorksDescriptionsTitleSecond.isHidden = true
            howItWorksDescriptionsTitleThird.isHidden = true
            howItWorksDescriptionsFirst.text = "Поучительные истории для вашего ребёнка, авторские развивающие сказки с интересными иллюстрациями"
            howItWorksDescriptionsSecond.text = "Ежемесячное обновление библиотеки и доступ к ней"
            howItWorksDescriptionsThird.text = "Оффлайн режим для чтения любимых сказок"

            backgroundImageView.image = UIImage(named: "special-gift-background")
            
            howItWorksIcon1.image = UIImage(named: "special-gift-descriptions-1")
            howItWorksIcon2.image = UIImage(named: "special-gift-descriptions-2")
            howItWorksIcon3.image = UIImage(named: "special-gift-descriptions-3")
        }
    }
}
