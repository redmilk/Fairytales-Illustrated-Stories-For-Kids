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
    }
}

// MARK: - StorySelectViewController

final class StorySelectViewController: BaseViewController, UserSessionServiceProvidable, ImageDownloaderProvidable {
    enum Buttons {
        case back, heart, gift, layout
    }
            
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var carousel: iCarousel!
    @IBOutlet weak var backButton: BaseButton!
    @IBOutlet weak var favoritesButton: BaseButton!
    @IBOutlet weak var giftButton: BaseButton!
    @IBOutlet weak var layoutButton: BaseButton!
    @IBOutlet weak var pageControl: UIPageControl!
    @IBOutlet weak var favoritesCounterLabel: UILabel!
    let imageViewForDownloadingPictures = UIImageView(frame: .zero)

    
    private lazy var displayDataManager = StorySelectDisplayManager(collectionView: self.collectionView)
    
    private var stateValue: State { state.value as! State }

    init(coordinator: Coordinatable, selectedCategory: CategorySection) {
        let initialState = State()
        initialState.layout = .line
        initialState.selectedCategory = selectedCategory
        super.init(coordinator: coordinator, type: Self.self, initialState: initialState)
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    deinit {
        Logger.log(String(describing: self), type: .deinited)
    }
    override func configure() {
        carousel.currentItemIndex = 1
        carousel.type = .linear
        carousel.delegate = self
        carousel.centerItemWhenSelected = true
        carousel.dataSource = self
        carousel.isPagingEnabled = true
        carousel.isScrollEnabled = true
        pageControl.preferredIndicatorImage = UIImage(named: "page-control-indicator")!
        displayDataManager.input.send(.configure(with: userSession.selectedCategory))
        userSession.selectedStory = stateValue.selectedCategory.items[safe: carousel.currentItemIndex]
        favoritesCounterLabel.text = userSession.favoritesCounter.description
        favoritesCounterLabel.isHidden = (favoritesCounterLabel.text ?? "0") == "0"
    }
    
    override func applyStyling() {
        let emitter = ParticleEmitterView()
        emitter.tag = 1
        emitter.alpha = 1
        emitter.isUserInteractionEnabled = false
        view.insertSubview(emitter, at: 1)
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
            case _: break
            }
        }).store(in: &bag)
        Publishers.MergeMany(
            backButton.publisher().map { _ in Buttons.back },
            favoritesButton.publisher().map { _ in Buttons.heart },
            giftButton.publisher().map { _ in Buttons.gift },
            layoutButton.publisher().map { _ in Buttons.layout })
            .sink(receiveValue: { [weak self] button in
                guard let self = self else { return }
                switch button {
                case .back: self.coordinator.end()
                case .heart:
                    break
                case .gift:
                    (self.coordinator as? StorySelectCoordinator)?.displaySpecialGift()
                case .layout:
                    let currentState = self.stateValue
                    currentState.layout = currentState.layout == .line ? .grid : .line
                    self.state.send(currentState)
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
                            if path.contains(".webp") {
                                self.imageViewForDownloadingPictures.kf.setImage(with: url, placeholder: nil, options: nil) { result in
                                    switch result {
                                    case .success(let imageResult):
                                        self.imageDownloader.cache.store(imageResult.image, forKey: path)
                                        promise(.success((imageResult.image, page)))
                                    case .failure(let error):
                                        Logger.logError(error)
                                        promise(.success((Constants.storyThumbnailPlaceholder, page)))
                                    }
                                    progressCurrentPage += progressCurrentPage < progressTotalPages ? 1 : 0
                                    let progress = progressCurrentPage / progressTotalPages
                                    item.updateProgress(progress)
                                    Logger.log(progressCurrentPage.description, type: .all)
                                }
                            } else {
                                var cancellable: AnyCancellable?
                                cancellable = self.imageDownloader.loadImage(withURL: url, cacheKey: path)
                                    .subscribe(on: Scheduler.backgroundWorkScheduler)
                                    .sink(receiveCompletion: { completion in
                                        switch completion {
                                        case .finished: break
                                        case .failure(let error):
                                            Logger.logError(error)
                                            promise(.success((Constants.storyThumbnailPlaceholder, page)))
                                        }
                                        progressCurrentPage += progressCurrentPage < progressTotalPages ? 1 : 0
                                        let progress = progressCurrentPage / progressTotalPages
                                        item.updateProgress(progress)
                                        Logger.log(progressCurrentPage.description, type: .all)
                                        cancellable?.cancel()
                                        cancellable = nil
                                    }, receiveValue: { image in
                                        promise(.success((image, page)))
                                    })
                            }
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
                completion?()
            })
    }
}

// MARK: - CarouselDelegate and CarouselDatasource

extension StorySelectViewController: iCarouselDelegate, iCarouselDataSource {
    func numberOfItems(in carousel: iCarousel) -> Int {
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
        recycled.openButtonCallback = { [weak self, weak recycled] in
            guard let recycled = recycled else { return }
            self?.loadStory(item: recycled, completion: {
                self?.loadStory(item: recycled, completion: {
                    self?.userSession.setStoryPersistanceStatusOn(with: item.dto.id_internal)
                    recycled.isPersisted = self?.userSession.checkIsStoryPersistedInStorage(with: item.dto.id_internal)
                    (self?.coordinator as? StorySelectCoordinator)?.displaySelectedStory()
                })
            })
        }
        recycled.heartButtonCallback = { [weak recycled, weak item, weak userSession, weak favoritesCounterLabel] in
            item?.isFavorite.toggle()
            recycled?.isFavorite = item?.isFavorite ?? false
            if let internalID = item?.dto.id_internal {
                userSession?.toggleFavorites(with: internalID)
            }
            favoritesCounterLabel?.text = userSession?.favoritesCounter.description
            favoritesCounterLabel?.isHidden = (favoritesCounterLabel?.text ?? "0") == "0"
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
