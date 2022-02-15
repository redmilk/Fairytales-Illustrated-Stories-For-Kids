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
        case heart, home, prevPage, nextPage
    }
            
    @IBOutlet weak var pageTextLabel: UILabel!
    @IBOutlet weak var pageImage: UIImageView!
    @IBOutlet weak var homeButton: BaseButton!
    @IBOutlet weak var favoritesButton: BaseButton!
    @IBOutlet weak var previousPageButton: BaseButton!
    @IBOutlet weak var nextPageButton: BaseButton!
    
    private var stateValue: State { state.value as! State }
    private var selectedStory: StoryModel { userSession.selectedStory }

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
                self?.navigationController?.setNavigationBarHidden(true, animated: false)
            case .viewDidDisappear:
                self?.navigationController?.setNavigationBarHidden(false, animated: false)
            case _: break
            }
        }).store(in: &bag)
        // buttons
        Publishers.MergeMany(
            homeButton.tapPublisher.map { _ in Buttons.home },
            favoritesButton.tapPublisher.map { _ in Buttons.heart },
            previousPageButton.tapPublisher.map { _ in Buttons.prevPage },
            nextPageButton.tapPublisher.map { _ in Buttons.nextPage })
            .sink(receiveValue: { [weak self] button in
                guard let self = self else { return }
                switch button {
                case .home: self.coordinator.end()
                case .heart:
                    break
                case .prevPage:
                    self.setupPreviousPage()
                case .nextPage:
                    self.setupNextPage()
                }
            }).store(in: &bag)
    }
    
    private func setupNextPage() {
        guard stateValue.currentPage + 1 < selectedStory.pagePictures.count && stateValue.currentPage + 1 < selectedStory.pages.count else { return }
        self.stateValue.currentPage += 1
        let image = userSession.selectedStory.pagePictures[stateValue.currentPage]
        let text = userSession.selectedStory.pages[stateValue.currentPage].text.getText(boy: userSession.isBoy, locale: userSession.locale)
        pageImage.image = image
        pageTextLabel.text = text
    }
    
    private func setupPreviousPage() {
        guard (stateValue.currentPage - 1) >= 0 && (stateValue.currentPage - 1) < selectedStory.pagePictures.count && (stateValue.currentPage - 1) < selectedStory.pages.count else { return }
        self.stateValue.currentPage -= 1
        let image = userSession.selectedStory.pagePictures[stateValue.currentPage]
        let text = userSession.selectedStory.pages[stateValue.currentPage].text.getText(boy: userSession.isBoy, locale: userSession.locale)
        pageImage.image = image
        pageTextLabel.text = text
    }
    
    private func loadStory() {
        let isGirl: Bool = false
        let isIpad: Bool = UIDevice.current.isIPad
        let educationalCategory = userSession.selectedStory.pages.publisher
        
        var loadPagesCancellable: AnyCancellable?
        startActivityAnimation()
        loadPagesCancellable = educationalCategory.flatMap({ pageModel -> AnyPublisher<(UIImage, String), Never> in
            Future<(UIImage, String), Never> ({ [weak self] promise in
                let path = pageModel.images.getImagePath(boy: isGirl, ipad: isIpad)
                let pictureLastPat: String = pageModel.images.girl_ipad
                FirebaseClient.shared.storage.reference(withPath: path).downloadURL(completion: { url, error in
                    if let error = error { Logger.logError(error) }
                    guard let url = url else { return promise(.success((Constants.storyThumbnailPlaceholder, pictureLastPat))) }
                    var cancellable: AnyCancellable?
                    cancellable = self?.imageDownloader.loadImage(withURL: url)
                        .subscribe(on: Scheduler.backgroundWorkScheduler)
                        .sink(receiveCompletion: { completion in
                            switch completion {
                            case .finished: break
                            case .failure(let error):
                                Logger.logError(error)
                                promise(.success((Constants.storyThumbnailPlaceholder, pictureLastPat)))
                            }
                            cancellable?.cancel()
                            cancellable = nil
                        }, receiveValue: { image in
                            promise(.success((image, pictureLastPat)))
                        })
                })
            })
            .eraseToAnyPublisher()
        })
            .print("BEFOR COLLECT")
            .collect()
            .print("AFTER COLLET")
            .receive(on: Scheduler.main, options: nil)
            .sink(receiveCompletion: { [weak self] completion in
                switch completion {
                case .finished:
                    let pages = self!.selectedStory.pagePictures
                    self?.setupNextPage()
                case .failure(let error): Logger.logError(error)
                }
                loadPagesCancellable?.cancel()
                loadPagesCancellable = nil
                self?.stopActivityAnimation()
            }, receiveValue: { [weak self] pagesImageList in
                self?.userSession.selectedStory.pagePictures = pagesImageList.sorted(by: { tupleL, tupleR in
                    tupleL.1 < tupleR.1
                }).compactMap { $0.0 }
                self?.stopActivityAnimation()
            })
    }
    
}
