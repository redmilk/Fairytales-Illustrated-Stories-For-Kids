//
//  
//  StorySelectViewController.swift
//  Fairytales
//
//  Created by Danyl Timofeyev on 31.01.2022.
//
//

import UIKit
import Combine

extension StorySelectViewController {
    class State: BaseState, UserSessionServiceProvidable {
        enum Layout {
            case line
            case grid
        }
        override init() { }
        var selectedCategory: CategorySection!
        var layout: Layout = .line
        var previousItem: CarouselItemView?
        var carouselCurrentItemIndex: Int = 0
        var isFirstSetup: Bool = true
        var isCarouselBlocked: Bool = false
        var isFavorites: Bool = false
        var isFirstOpen: Bool = true
    }
}

// MARK: - StorySelectViewController

final class StorySelectViewController: BaseViewController, UserSessionServiceProvidable, ImageDownloaderProvidable, PurchesServiceProvidable {
    enum Buttons {
        case back, heart, gift, layout, closeDescription, startReadFromDescription, emptyFavoritesOk
    }
            
    @IBOutlet weak var favoritesBackgroundView: UIView!
    @IBOutlet weak var menuBackground: UIImageView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var carousel: iCarousel!
    @IBOutlet weak var backButton: BaseButton!
    @IBOutlet weak var favoritesButton: BaseButton!
    @IBOutlet weak var giftButton: BaseButton!
    @IBOutlet weak var layoutButton: BaseButton!
    @IBOutlet weak var pageControl: UIPageControl!
    @IBOutlet weak var favoritesCounterLabel: UILabel!
    // story description container
    @IBOutlet weak var storyDescriptionContainer: UIView!
    @IBOutlet weak var storyDescriptionCloseButton: BaseButton!
    @IBOutlet weak var storyDescriptionButton: BaseButton!
    @IBOutlet weak var storyDescriptionLabel: UILabel!
    @IBOutlet weak var sotryDescriptionImage: UIImageView!
    // empty favorites popup
    @IBOutlet weak var emptyFavoritesContainer: UIView!
    @IBOutlet weak var emptyFavoritesButton: BaseButton!
    @IBOutlet weak var emptyFavoritesBackgroundImageView: UIImageView!
    
    private var storyDescriptionStartReadingAction: VoidClosure?
    private lazy var displayDataManager = StorySelectDisplayManager(collectionView: self.collectionView)
    private var stateValue: State { state.value as! State }

    init(coordinator: Coordinatable, selectedCategory: CategorySection, isFavorites: Bool) {
        let initialState = State()
        initialState.layout = .line
        initialState.selectedCategory = selectedCategory
        initialState.isFavorites = isFavorites
        super.init(coordinator: coordinator, type: Self.self, initialState: initialState)
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    deinit {
        Logger.log(String(describing: self), type: .deinited)
    }
    override func configure() {
        carousel.currentItemIndex = 0
        carousel.type = .linear
        carousel.delegate = self
        carousel.centerItemWhenSelected = true
        carousel.dataSource = self
        carousel.isPagingEnabled = true
        carousel.isScrollEnabled = true
        pageControl.preferredIndicatorImage = UIImage(named: "page-control-indicator")!
        displayDataManager.input.send(.configure(with: userSession.selectedCategory))
        userSession.selectedStory = stateValue.selectedCategory.items[safe: carousel.currentItemIndex]
        sotryDescriptionImage.layer.borderColor = UIColor.white.cgColor
        sotryDescriptionImage.layer.borderWidth = 5
        emptyFavoritesBackgroundImageView.layer.borderWidth = 5
        emptyFavoritesBackgroundImageView.layer.borderColor = UIColor.white.cgColor
        emptyFavoritesBackgroundImageView.layer.cornerRadius = 30
        emptyFavoritesContainer.layer.borderColor = UIColor.white.cgColor
        emptyFavoritesContainer.isHidden = !(stateValue.isFavorites && userSession.favoritesCounter == 0)
        
        giftButton.isHidden = purchases.isUserHasActiveSubscription
        if purchases.isUserHasActiveSubscription {
            giftButton.dropShadow(color: .yellow, opacity: 0.0, offSet: .zero, radius: 10, scale: true)
            giftButton.animateShakeRepeatedly()?.store(in: &bag)
        }
        menuBackground.isHidden = !stateValue.isFavorites
        favoritesBackgroundView.isHidden = !stateValue.isFavorites
        favoritesButton.isHidden = stateValue.isFavorites
    }
    
    override func applyStyling() {
        let emitter = ParticleEmitterView()
        emitter.tag = 1
        emitter.alpha = 1
        emitter.isUserInteractionEnabled = false
        view.insertSubview(emitter, aboveSubview: favoritesBackgroundView)
        //view.insertSubview(emitter, at: 1)
        emitter.constraintToSides(inside: view)
    }
    
    override func handleState() {
        state.compactMap { $0 as? StorySelectViewController.State }
            .sink(receiveValue: { [weak self] state in
                guard let self = self else { return }
                switch state.layout {
                case .grid:
                    self.displayDataManager.input.send(.populate(with: state.selectedCategory.items))
                case .line:
                    self.carousel.currentItemIndex = state.carouselCurrentItemIndex
                }
                self.view.backgroundColor = state.selectedCategory.color
                self.collectionView.isHidden = state.layout == .line
                self.carousel.isHidden = state.layout == .grid
                self.layoutButton.isSelected = state.layout == .grid
                self.pageControl.isHidden = state.layout == .grid
                self.pageControl.numberOfPages = state.selectedCategory.items.count
                self.pageControl.currentPage = state.carouselCurrentItemIndex
            }).store(in: &bag)
    }
    
    override func handleEvents() {
        // lifecycle
        lifecycle.sink(receiveValue: { [weak self] lifecycle in
            guard let self = self else { return }
            switch lifecycle {
            case .viewWillAppear:
                self.navigationController?.setNavigationBarHidden(true, animated: false)
                self.favoritesCounterLabel.text = self.userSession.favoritesCounter.description
                self.favoritesCounterLabel.isHidden = (self.favoritesCounterLabel.text ?? "0") == "0"
                self.favoritesCounterLabel.isHidden = self.stateValue.isFavorites
                //if self.stateValue.isFavorites {
                if !self.stateValue.isFirstOpen {
                    self.carousel.reloadData()
                }
                //}
            case .viewDidAppear:
                //if self.stateValue.isFavorites {
                self.stateValue.previousItem = (self.carousel.currentItemView as? CarouselItemView)
                if !self.stateValue.isFirstOpen {
                    (self.carousel.currentItemView as? CarouselItemView)?.layoutState = .selected
                }
                self.stateValue.isFirstOpen = false
                //}
            case _: break
            }
        }).store(in: &bag)
        Publishers.MergeMany(
            backButton.publisher().map { _ in Buttons.back },
            favoritesButton.publisher().map { _ in Buttons.heart },
            giftButton.publisher().map { _ in Buttons.gift },
            layoutButton.publisher().map { _ in Buttons.layout },
            storyDescriptionCloseButton.publisher().map { _ in Buttons.closeDescription },
            storyDescriptionButton.publisher().map { _ in Buttons.startReadFromDescription },
            emptyFavoritesButton.publisher().map { _ in Buttons.emptyFavoritesOk }
        ).sink(receiveValue: { [weak self] button in
                guard let self = self else { return }
                switch button {
                case .back: self.coordinator.end()
                case .heart: (self.coordinator as? StorySelectCoordinator)?.displayFavorites()
                case .gift:
                    (self.coordinator as? StorySelectCoordinator)?.displaySpecialGift()
                case .layout:
                    let currentState = self.stateValue
                    currentState.layout = currentState.layout == .line ? .grid : .line
                    self.state.send(currentState)
                case .closeDescription:
                    self.storyDescriptionContainer.isHidden = true
                case .startReadFromDescription:
                    self.storyDescriptionStartReadingAction?()
                    self.storyDescriptionContainer.isHidden = true
                case .emptyFavoritesOk:
                    self.coordinator.end()
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
}

// MARK: - Loading story
private extension StorySelectViewController {
    func loadStory(item: CarouselItemView, completion: VoidClosure?) {
        var progressTotalPages: CGFloat = CGFloat(userSession.selectedStory.dto.pages.count)
        var progressCurrentPage: CGFloat = 0
        let isBoy: Bool = userSession.isBoy
        let isIpad: Bool = UIDevice.current.isIPad
        let educationalCategory = userSession.selectedStory.pages.publisher
        let basePath = userSession.selectedStory.dto.storage_path
        var loadPagesCancellable: AnyCancellable?
       // startActivityAnimation()
        item.startAnimateDownloading()
        loadPagesCancellable = educationalCategory.flatMap({ pageModel -> AnyPublisher<(UIImage, Int), Never> in
            Future<(UIImage, Int), Never> ({ [weak self] promise in
                guard let self = self else { return }
                let page = Int(pageModel.page)!
                let imagePath = pageModel.images.getImagePath(boy: isBoy, ipad: isIpad)
                let path = basePath + imagePath
                                
                Logger.log(path, type: .purchase)
                self.imageDownloader.fetchFromCache(path).sink(receiveValue: { image in
                    if let img = image {
                        promise(.success((img, page)))
                    } else {
                        FirebaseClient.shared.storage.reference(withPath: path).downloadURL(completion: { url, error in
                            if let error = error { Logger.logError(error) }
                            guard let url = url else { return promise(.success((Constants.storyThumbnailPlaceholder, page))) }
                            print(url.absoluteString)
                            var cancellable: AnyCancellable?
                            cancellable = self.imageDownloader.loadImage(withURL: url, cacheKey: path)
                                .subscribe(on: Scheduler.backgroundWorkScheduler)
                                .sink(receiveCompletion: { completion in
                                    switch completion {
                                    case .finished: break
                                    case .failure(let error):
                                        Logger.logError(error)
                                        progressCurrentPage += progressCurrentPage < progressTotalPages ? 1 : 0
                                        let progress = progressCurrentPage / progressTotalPages
                                        DispatchQueue.main.async {
                                            item.updateProgress(progress)
                                        }
                                        Logger.log(progressCurrentPage.description, type: .all)
                                        promise(.success((Constants.storyThumbnailPlaceholder, page)))
                                    }
                                    cancellable?.cancel()
                                    cancellable = nil
                                }, receiveValue: { image in
                                    self.imageDownloader.cache.store(image, forKey: path)
                                    progressCurrentPage += progressCurrentPage < progressTotalPages ? 1 : 0
                                    let progress = progressCurrentPage / progressTotalPages
                                    DispatchQueue.main.async {
                                        item.updateProgress(progress)
                                    }
                                    Logger.log(progressCurrentPage.description, type: .all)
                                    promise(.success((image, page)))
                                })
                        })
                    }
                }).store(in: &self.bag)
            }).eraseToAnyPublisher()
        }).collect()
            .receive(on: Scheduler.main, options: nil)
            .sink(receiveCompletion: { [weak self, weak item] completion in
                item?.stopAnimateDownloading()
                switch completion {
                case .finished: break
                case .failure(let error): Logger.logError(error)
                }
                loadPagesCancellable?.cancel()
                loadPagesCancellable = nil
            }, receiveValue: { [weak self, weak item] pagesImageList in
                item?.stopAnimateDownloading()
                self?.userSession.selectedStory.pagePictures = pagesImageList.sorted(by: { $0.1 < $1.1 }).map { $0.0 }
                self?.favoritesCounterLabel.text = self?.userSession.favoritesCounter.description ?? "0"
                self?.favoritesCounterLabel.isHidden = (self?.favoritesCounterLabel.text ?? "0") == "0"
                self?.favoritesCounterLabel.isHidden = self?.stateValue.isFavorites ?? true
                completion?()
            })
    }
    
    func shouldShowSubscriptionsPopup() -> Bool {
        if carousel.currentItemIndex == 0 {
            return false
        } else if carousel.currentItemIndex > 0 && purchases.isUserHasActiveSubscription {
            return false
        } else {
            return true
        }
    }
    
    func openStoryAction(_ recycled: CarouselItemView, storyModel item: StoryModel) {
        recycled.isLoading = true
        self.carousel.isUserInteractionEnabled = false
        self.loadStory(item: recycled, completion: {
            recycled.isLoading = false
            self.carousel.isUserInteractionEnabled = true
            self.userSession.setStoryPersistanceStatusOn(with: item.dto.id_internal)
            recycled.isPersisted = self.userSession.checkIsStoryPersistedInStorage(with: item.dto.id_internal)
            self.shouldShowSubscriptionsPopup() ?
            (self.coordinator as? StorySelectCoordinator)?.displaySubscriptionsPopup() :
            (self.coordinator as? StorySelectCoordinator)?.displaySelectedStory()
        })
    }
}

// MARK: - CarouselDelegate and CarouselDatasource

extension StorySelectViewController: iCarouselDelegate, iCarouselDataSource {
    func numberOfItems(in carousel: iCarousel) -> Int {
        pageControl.isHidden = stateValue.selectedCategory.items.count == 0
        emptyFavoritesContainer.isHidden = !(stateValue.selectedCategory.items.count == 0 && stateValue.isFavorites)
        return stateValue.selectedCategory.items.count
    }
    func carousel(_ carousel: iCarousel, viewForItemAt index: Int, reusing view: UIView?) -> UIView {
        var recycled: CarouselItemView
        if let node = view as? CarouselItemView {
            recycled = node
        } else {
            let node = CarouselItemView(frame: .init(origin: .zero, size: CGSize(width: Constants.storySelectWidth, height: Constants.storySelectWidth)))
            recycled = node
        }
        let item = stateValue.selectedCategory.items[index]
        recycled.configure(with: item)
        let isFavorite = userSession.checkIsStoryFavorite(with: item.dto.id_internal)
        recycled.heartButton.isSelected = isFavorite
        item.isFavorite = isFavorite
        recycled.isPersisted = userSession.checkIsStoryPersistedInStorage(with: item.dto.id_internal)
        recycled.openButtonCallback = { [weak self, weak recycled, weak item] in
            guard let self = self, let recycled = recycled, let item = item else { return }
            self.openStoryAction(recycled, storyModel: item)
        }
        recycled.heartButtonCallback = { [weak recycled, weak item, weak userSession, weak favoritesCounterLabel] in
            item?.isFavorite.toggle()
            recycled?.isFavorite = item?.isFavorite ?? false
            if let internalID = item?.dto.id_internal {
                userSession?.toggleFavorites(with: internalID)
            }
            favoritesCounterLabel?.text = userSession?.favoritesCounter.description
            favoritesCounterLabel?.isHidden = (favoritesCounterLabel?.text ?? "0") == "0"
            favoritesCounterLabel?.isHidden = self.stateValue.isFavorites
            if self.stateValue.isFavorites, let isFavorite = recycled?.isFavorite, !isFavorite {
                let index = self.stateValue.selectedCategory.items.firstIndex { story in
                    story.dto.id_internal == item?.dto.id_internal
                }
                if let index = index {
                    self.stateValue.selectedCategory.items.remove(at: index)
                    self.pageControl.numberOfPages = self.stateValue.selectedCategory.items.count
                    self.pageControl.currentPage = self.carousel.currentItemIndex
                    carousel.reloadData()
                }
            }
        }
        recycled.infoButtonCallback = { [weak self, weak item] in
            guard let self = self, let item = item else { return }
            if let storyDescription = item.dto.description?["ru"] {
                self.storyDescriptionLabel.text = storyDescription
                self.storyDescriptionContainer.isHidden = false
            }
            self.sotryDescriptionImage.image = item.imageThumbnail ?? UIImage(named: "story-info-background")
            self.storyDescriptionStartReadingAction = nil
            self.storyDescriptionStartReadingAction = {
                self.openStoryAction(recycled, storyModel: item)
            }
        }
        if stateValue.isFirstSetup {
            recycled.layoutState = .selected
            stateValue.isFirstSetup = false
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
            return stateValue.selectedCategory.items.count > 2 ? 1 : 0
        }
        return value
    }
    func carouselCurrentItemIndexDidChange(_ carousel: iCarousel) {
        pageControl.currentPage = carousel.currentItemIndex
        if let node = carousel.currentItemView as? CarouselItemView {
            node.layoutState = .selected
            stateValue.previousItem?.layoutState = .idle
            stateValue.previousItem = node
            userSession.selectedStory = stateValue.selectedCategory.items[safe: carousel.currentItemIndex]
        }
        
    }
    func carousel(_ carousel: iCarousel, didSelectItemAt index: Int) {
        guard index != carousel.currentItemIndex else { return }
        if let node = carousel.currentItemView as? CarouselItemView {
            node.layoutState = .idle
        }
    }
}
