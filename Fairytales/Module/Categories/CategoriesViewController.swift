//
//  
//  CategoriesViewController.swift
//  Fairytales
//
//  Created by Danyl Timofeyev on 14.01.2022.
//
//

import UIKit
import Combine

// MARK: - CategoriesViewController

final class CategoriesViewController: BaseViewController, UserSessionServiceProvidable, PurchesServiceProvidable {
    enum Button {
        case settings, favorites, gift
    }
    
    @IBOutlet weak var giftButton: BaseButton!
    @IBOutlet weak var favoritesButton: BaseButton!
    @IBOutlet weak var settingsButton: BaseButton!
    @IBOutlet weak var carousel: iCarousel!
    @IBOutlet weak var pageControl: UIPageControl!
    @IBOutlet weak var favoritesCounterLabel: UILabel!
    private lazy var fDisplayManager = CategoriesDisplayManager()
    private var categories: [CategorySection] = []
    private var previousItem: CarouselItemView?
    private var giftButtonAnimCancelable: AnyCancellable?
    
    init(coordinator: Coordinatable) {
        super.init(coordinator: coordinator, type: Self.self, initialState: BaseState())
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    deinit {
        Logger.log(String(describing: self), type: .deinited)
    }
    
    override func configure() {
        loadData()
        
        carousel.type = .linear
        carousel.delegate = self
        carousel.centerItemWhenSelected = true
        carousel.dataSource = self
        carousel.isPagingEnabled = true
        carousel.isScrollEnabled = true
        carousel.currentItemIndex = 1
        pageControl.numberOfPages = categories.count
        pageControl.currentPage = 1
        pageControl.preferredIndicatorImage = UIImage(named: "page-control-indicator")!
        
        giftButton.isHidden = purchases.isUserHasActiveSubscription
        if purchases.isUserHasActiveSubscription {
            giftButton.dropShadow(color: .yellow, opacity: 0.0, offSet: .zero, radius: 10, scale: true)
            giftButtonAnimCancelable?.cancel()
            giftButtonAnimCancelable = giftButton.animateShakeRepeatedly()
        }
    }
    override func applyStyling() {
        let emitter = ParticleEmitterView()
        emitter.tag = 1
        emitter.alpha = 1
        emitter.isUserInteractionEnabled = false
        view.insertSubview(emitter, at: 1)
        emitter.constraintToSides(inside: view)
    }
    override func handleEvents() {
        // buttons
        Publishers.MergeMany(
            giftButton.publisher().map { _ in Button.gift },
            favoritesButton.publisher().map { _ in Button.favorites },
            settingsButton.publisher().map { _ in Button.settings })
            .sink(receiveValue: { [weak self] button in
                guard let self = self else { return }
                switch button {
                case .settings: (self.coordinator as? CategoriesCoordinator)?.displaySettings()
                case .favorites: (self.coordinator as? CategoriesCoordinator)?.displayFavorites()
                case .gift: (self.coordinator as? CategoriesCoordinator)?.displaySpecialGift()
                }
            }).store(in: &bag)
        // lifecycle
        lifecycle.sink(receiveValue: { [weak self] lifecycle in
            guard let self = self else { return }
            switch lifecycle {
            case .viewWillAppear:
                self.navigationController?.setNavigationBarHidden(true, animated: false)
                self.favoritesCounterLabel.text = self.userSession.favoritesCounter.description
                self.favoritesCounterLabel.isHidden = (self.favoritesCounterLabel.text ?? "0") == "0"
            case _: break
            }
        }).store(in: &bag)
        
        purchases.output.receive(on: DispatchQueue.main, options: nil)
            .sink(receiveValue: { [weak self] event in
            switch event {
            case .successfullyPurchased:
                self?.giftButton.isHidden = true
            case _: break
            }
        }).store(in: &bag)
    }
    
    private func loadData() {
        startActivityAnimation()
        FirebaseClient.shared.signInAnonim()
        FirebaseClient.shared.userSubject
            .compactMap { $0 }
            .sink(receiveValue: { [weak self] user in
                guard let self = self else { return }
                FirebaseClient.shared.requestAllFairytalesAndMakeCategories(isForBoy: self.userSession.isBoy)
                FirebaseClient.shared.categoriesInternalType
                    .compactMap { $0 }
                    .sink(receiveCompletion: { [weak self] completion in
                        self?.stopActivityAnimation()
                        switch completion {
                        case .finished: break
                        case .failure(let error): Logger.logError(error)
                        }
                    }, receiveValue: { [weak self] cats in
                        self?.userSession.categories.removeAll()
                        self?.userSession.categories = cats
                        self?.categories = cats.toSortedArray
                        self?.stopActivityAnimation()
                        self?.carousel.reloadData()
                    }).store(in: &self.bag)
            }).store(in: &bag)
    }
}

// MARK: - CarouselDelegate and CarouselDatasource

extension CategoriesViewController: iCarouselDelegate, iCarouselDataSource {
    func numberOfItems(in carousel: iCarousel) -> Int {
        return categories.count
    }
    
    func carousel(_ carousel: iCarousel, viewForItemAt index: Int, reusing view: UIView?) -> UIView {
        var recycled: CarouselItemView

        if let node = view as? CarouselItemView {
            recycled = node
        } else {
            let node = CarouselItemView(frame: .init(origin: .zero, size: CGSize(width: Constants.menuItemWidth, height: Constants.menuItemHeight)))
            recycled = node
        }
        
        let category = categories[index]
        recycled.configure(with: category)
        recycled.openButtonCallback = { [weak self] in
            let coordinator = StorySelectCoordinator(navigationController: self?.navigationController)
            coordinator.start()
        }
        return recycled
    }
    
    func carousel(_ carousel: iCarousel, valueFor option: iCarouselOption, withDefault value: CGFloat) -> CGFloat {
        if (option == .spacing) {
            return value * 1.11
        }
        if (option == .visibleItems) {
            return 3
        }
        if (option == .wrap) {
            return 1
        }
        if (option == .count) {
            return 8
        }
        return value
    }
    
    func carouselCurrentItemIndexDidChange(_ carousel: iCarousel) {
        if let node = carousel.currentItemView as? CarouselItemView {
            node.layoutState = .selected
            previousItem?.layoutState = .idle
            previousItem = node
            
            userSession.selectedCategory = userSession.categories.toSortedArray[carousel.currentItemIndex]
            self.view.layer.removeAllAnimations()
            UIView.animate(withDuration: 1, delay: 0, options: [.allowUserInteraction], animations: {
                self.view.backgroundColor = self.userSession.selectedCategory.color
            }, completion: nil)
            pageControl.currentPage = carousel.currentItemIndex
        }
    }
    
    func carousel(_ carousel: iCarousel, didSelectItemAt index: Int) {
        //userSession.selectedCategory = userSession.categories.toSortedArray[carousel.currentItemIndex]
        guard index != carousel.currentItemIndex else { return }
        if let node = carousel.currentItemView as? CarouselItemView {
            node.layoutState = .idle
        }
    }
}
