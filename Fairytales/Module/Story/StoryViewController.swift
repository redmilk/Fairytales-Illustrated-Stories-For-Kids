//
//  
//  StoryViewController.swift
//  Fairytales
//
//  Created by Danyl Timofeyev on 14.01.2022.
//
//

import UIKit
import Combine

extension StoryViewController {
    class State: BaseState {
        var currentPage: Int
        var pagesTotal: Int
        var pageImage: UIImage
        var pageText: String

        init(pageImage: UIImage, pageText: String, currentPage: Int = -1, pagesTotal: Int = 0) {
            self.currentPage = currentPage
            self.pagesTotal = pagesTotal
            self.pageText = pageText
            self.pageImage = pageImage
        }
    }
}

// MARK: - StorySelectViewController

final class StoryViewController: BaseViewController, UserSessionServiceProvidable, ImageDownloaderProvidable {
    enum Buttons {
        case heart, home, prevPage, nextPage, readAgain, selectNewStory
    }
            
    @IBOutlet weak var currentPageNumberLabel: UIButton!
    @IBOutlet weak var maxPageNumberLabel: UILabel!
    @IBOutlet weak var pageTextLabel: UILabel!
    @IBOutlet weak var pageImage: UIImageView!
    @IBOutlet weak var homeButton: BaseButton!
    @IBOutlet weak var favoritesButton: BaseButton!
    @IBOutlet weak var previousPageButton: BaseButton!
    @IBOutlet weak var nextPageButton: BaseButton!
    // end story
    @IBOutlet weak var endStoryContainer: UIView!
    @IBOutlet weak var endStoryTitleLabel: UILabel!
    @IBOutlet weak var endStoryDescriptionLabel: UILabel!
    @IBOutlet weak var endStoryReadAgainButton: BaseButton!
    @IBOutlet weak var endStorySelectNewStoryButton: BaseButton!
    
    @IBOutlet weak var favoritesCounterLabel: UILabel!
    
    private var stateValue: State { state.value as! State }
    private var selectedStory: StoryModel { userSession.selectedStory }
    private let storyTextFormatter = StoryTextFormatter()

    init(coordinator: Coordinatable) {
        let initialState = State(pageImage: UIImage(named: "story-thumbnail-2")!, pageText: "Loading the fairytale...")
        super.init(coordinator: coordinator, type: Self.self, initialState: initialState)
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    deinit {
        Logger.log(String(describing: self), type: .deinited)
    }
    override func configure() {
        loadStory()
    }
    override func handleEvents() {
        // lifecycle
        lifecycle.sink(receiveValue: { [weak self] lifecycle in
            switch lifecycle {
            case .viewWillAppear:
                guard let self = self else { return }
                self.navigationController?.setNavigationBarHidden(true, animated: false)
                self.favoritesButton.isSelected = self.userSession.checkIsStoryFavorite(with: self.userSession.selectedStory.dto.id_internal)
            case .viewDidDisappear:
                self?.navigationController?.setNavigationBarHidden(false, animated: false)
                if let page = self?.stateValue.currentPage {
                    self?.userSession.saveCurrentPageOfSelectedStory(page)
                }
            case _: break
            }
        }).store(in: &bag)
        // buttons
        Publishers.MergeMany(
            homeButton.publisher().map { _ in Buttons.home },
            favoritesButton.publisher().map { _ in Buttons.heart },
            previousPageButton.publisher().map { _ in Buttons.prevPage },
            nextPageButton.publisher().map { _ in Buttons.nextPage },
            endStoryReadAgainButton.publisher().map { _ in Buttons.readAgain },
            endStorySelectNewStoryButton.publisher().map { _ in Buttons.selectNewStory })
            .sink(receiveValue: { [weak self] button in
                guard let self = self else { return }
                switch button {
                case .home: self.coordinator.end()
                case .heart:
                    let isOn = self.userSession.toggleFavorites(with: self.selectedStory.dto.id_internal)
                    self.favoritesButton.isSelected = isOn.0
                    self.favoritesCounterLabel.isHidden = isOn.1 <= 0
                    self.favoritesCounterLabel.text = isOn.1.description
                case .prevPage:
                    self.setupPreviousPage()
                case .nextPage:
                    self.setupNextPage()
                case .readAgain:
                    self.stateValue.currentPage = -1
                    self.userSession.saveCurrentPageOfSelectedStory(0)
                    self.setupNextPage()
                    self.endStoryContainer.isHidden = true
                case .selectNewStory:
                    self.coordinator.end()
                }
            }).store(in: &bag)
    }
    
    private func setupNextPage() {
        guard stateValue.currentPage + 1 < selectedStory.pagePictures.count && stateValue.currentPage + 1 < selectedStory.pages.count else {
            endStoryContainer.isHidden = false
            return
        }
        Logger.log(stateValue.currentPage.description, type: .purchase)
        self.stateValue.currentPage += 1
        Logger.log(stateValue.currentPage.description, type: .purchase)
        Logger.log(userSession.selectedStory.pagePictures.count.description, type: .purchase)
        let index = max(0, stateValue.currentPage)
        let image = userSession.selectedStory.pagePictures[index]
        let text = userSession.selectedStory.pages[index].text.getText(boy: userSession.isBoy, locale: userSession.locale)
        pageImage.kf.base.image = image
        pageTextLabel.text = text
        maxPageNumberLabel.text = stateValue.pagesTotal.description
        currentPageNumberLabel.setTitle((index + 1).description, for: .normal)
    }
    
    private func setupPreviousPage() {
        guard (stateValue.currentPage - 1) >= 0 && (stateValue.currentPage - 1) < selectedStory.pagePictures.count && (stateValue.currentPage - 1) < selectedStory.pages.count else { return }
        self.stateValue.currentPage -= 1
        let image = userSession.selectedStory.pagePictures[stateValue.currentPage]
        let text = userSession.selectedStory.pages[stateValue.currentPage].text.getText(boy: userSession.isBoy, locale: userSession.locale)
        pageImage.image = image
        pageTextLabel.text = text
        maxPageNumberLabel.text = stateValue.pagesTotal.description
        currentPageNumberLabel.setTitle((stateValue.currentPage + 1).description, for: .normal)
    }
    
    private func loadStory() {
        let imageViewForDownloadingPictures = UIImageView(frame: .zero)
        let isBoy: Bool = userSession.isBoy
        let isIpad: Bool = UIDevice.current.isIPad
        let educationalCategory = userSession.selectedStory.pages.publisher
        let basePath = userSession.selectedStory.dto.storage_path
        var loadPagesCancellable: AnyCancellable?
        startActivityAnimation()
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
                                imageViewForDownloadingPictures.kf.setImage(with: url, placeholder: nil, options: nil) { result in
                                    switch result {
                                    case .success(let imageResult):
                                        promise(.success((imageResult.image, page)))
                                        self.imageDownloader.cache.store(imageResult.image, forKey: path)
                                    case .failure(let error):
                                        Logger.logError(error)
                                        promise(.success((Constants.storyThumbnailPlaceholder, page)))
                                    }
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
            .sink(receiveCompletion: { [weak self] completion in
                switch completion {
                case .finished: break
                case .failure(let error): Logger.logError(error)
                }
                loadPagesCancellable?.cancel()
                loadPagesCancellable = nil
                self?.stopActivityAnimation()
            }, receiveValue: { [weak self] pagesImageList in
                self?.userSession.selectedStory.pagePictures = pagesImageList.sorted(by: { $0.1 < $1.1 }).map { $0.0 }
//                self?.userSession.selectedStory.pagePictures = pagesImageList.sorted(by: { tupleL, tupleR in
//                    tupleL.0.accessibilityIdentifier ?? "" < tupleR.0.accessibilityIdentifier ?? ""
//                }).compactMap { $0.0 }
                if let currentPage = self?.userSession.currentPageNumber {
                    self?.stateValue.currentPage = currentPage - 1
                }
                self?.stateValue.pagesTotal = pagesImageList.count
                
                let pages = self!.selectedStory.pagePictures
                self?.setupNextPage()
                self?.stateValue.pagesTotal = pages.count
                self?.favoritesCounterLabel.text = self?.userSession.favoritesCounter.description ?? "0"
                self?.favoritesCounterLabel.isHidden = (self?.favoritesCounterLabel.text ?? "0") == "0"
                self?.stopActivityAnimation()
            })
    }
    
}
