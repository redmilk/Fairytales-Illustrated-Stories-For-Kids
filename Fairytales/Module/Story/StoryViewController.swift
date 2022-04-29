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
        case heart, home, prevPage, nextPage, readAgain, selectNewStory, closeSharePopup, sharePressed
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
    @IBOutlet weak var popoverShare: UIView!
    // end story popup
    @IBOutlet weak var sharePopupContainerView: UIView!
    @IBOutlet weak var shareCloseButton: BaseButton!
    @IBOutlet weak var shareButton: BaseButton!
    @IBOutlet weak var pageTextContainer: UIStackView!
    
    private var panRecognizer: UIPanGestureRecognizer!
    private var stateValue: State { state.value as! State }
    private var selectedStory: StoryModel { userSession.selectedStory }
    private let storyTextFormatter = StoryTextFormatter()
    private var startLocation: CGPoint!
    private var swipeDistance: CGFloat!

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
        stateValue.currentPage = userSession.currentPageNumber - 1
        stateValue.pagesTotal = selectedStory.pages.count
        favoritesCounterLabel.text = userSession.favoritesCounter.description
        favoritesCounterLabel.isHidden = (favoritesCounterLabel.text ?? "0") == "0"
        setupNextPage()
        panRecognizer = UIPanGestureRecognizer(target: self, action:  #selector(panedView))
        self.view.addGestureRecognizer(panRecognizer)
    }
    override func handleEvents() {
        // lifecycle
        lifecycle.sink(receiveValue: { [weak self] lifecycle in
            switch lifecycle {
            case .viewWillAppear:
                guard let self = self else { return }
                self.navigationController?.setNavigationBarHidden(true, animated: false)
                self.favoritesButton.isSelected = self.userSession.checkIsStoryFavorite(with: self.userSession.selectedStory.dto.id_internal)
                self.swipeDistance = self.view.bounds.width * 0.1
            case .viewDidDisappear:
                self?.navigationController?.setNavigationBarHidden(false, animated: false)
                if let page = self?.stateValue.currentPage {
                    self?.userSession.saveCurrentPageOfSelectedStory(page)
                }
            case .viewDidAppear: break
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
            endStorySelectNewStoryButton.publisher().map { _ in Buttons.selectNewStory },
            shareCloseButton.publisher().map { _ in Buttons.closeSharePopup },
            shareButton.publisher().map { _ in Buttons.sharePressed }
        ).sink(receiveValue: { [weak self] button in
                guard let self = self else { return }
                switch button {
                case .home: self.coordinator.end()
                case .heart:
                    let isOn = self.userSession.toggleFavorites(with: self.selectedStory.dto.id_internal)
                    self.favoritesButton.isSelected = isOn.0
                    self.favoritesCounterLabel.isHidden = isOn.1 <= 0
                    self.favoritesCounterLabel.text = isOn.1.description
                    self.selectedStory.isFavorite.toggle()
                case .prevPage:
                    self.setupPreviousPage()
                    self.saveCurrentPage()
                case .nextPage:
                    self.setupNextPage()
                    self.saveCurrentPage()
                case .readAgain:
                    self.stateValue.currentPage = -1
                    self.userSession.saveCurrentPageOfSelectedStory(0)
                    self.setupNextPage()
                    self.endStoryContainer.isHidden = true
                    self.panRecognizer.isEnabled = true
                    self.nextPageButton.isHidden = false
                    self.previousPageButton.isHidden = false
                    self.pageTextContainer.isHidden = false
                    self.pageTextLabel.isHidden = false
                case .selectNewStory:
                    self.coordinator.end()
                case .closeSharePopup:
                    self.sharePopupContainerView.isHidden = true
                case .sharePressed:
                    self.shareApp()
                    self.sharePopupContainerView.isHidden = true
                }
            }).store(in: &bag)
    }
    
    private func saveCurrentPage() {
        userSession.saveCurrentPageOfSelectedStory(stateValue.currentPage)
    }
    
    private func setupNextPage() {
        guard stateValue.currentPage + 1 < selectedStory.pagePictures.count && stateValue.currentPage + 1 < selectedStory.pages.count else {
            endStoryContainer.isHidden = false
            sharePopupContainerView.isHidden = false
            pageTextLabel.isHidden = true
            pageTextContainer.isHidden = true
            previousPageButton.isHidden = true
            nextPageButton.isHidden = true
            panRecognizer.isEnabled = false
            return
        }
        Logger.log(stateValue.currentPage.description, type: .purchase)
        self.stateValue.currentPage += 1
        Logger.log(stateValue.currentPage.description, type: .purchase)
        Logger.log(userSession.selectedStory.pagePictures.count.description, type: .purchase)
        let index = max(0, stateValue.currentPage)
        let image = userSession.selectedStory.pagePictures[index]
        let text = userSession.selectedStory.pages[index].text.getText(boy: userSession.isBoy, locale: userSession.locale)
        UIView.transition(with: self.view, duration: 1, options: [.transitionCurlUp, .allowUserInteraction], animations: { [weak self] in
            self?.pageImage.image = image
        }, completion: nil)
        pageTextLabel.text = text
        maxPageNumberLabel.text = stateValue.pagesTotal.description
        currentPageNumberLabel.setTitle((index + 1).description, for: .normal)
    }
    
    private func setupPreviousPage() {
        endStoryContainer.isHidden = true
        guard (stateValue.currentPage - 1) >= 0 && (stateValue.currentPage - 1) < selectedStory.pagePictures.count && (stateValue.currentPage - 1) < selectedStory.pages.count else { return }
        self.stateValue.currentPage -= 1
        let image = userSession.selectedStory.pagePictures[stateValue.currentPage]
        let text = userSession.selectedStory.pages[stateValue.currentPage].text.getText(boy: userSession.isBoy, locale: userSession.locale)
        UIView.transition(with: self.view, duration: 1, options: [.transitionCurlDown, .allowUserInteraction], animations: { [weak self] in
            self?.pageImage.image = image
        }, completion: nil)
        pageTextLabel.text = text
        maxPageNumberLabel.text = stateValue.pagesTotal.description
        currentPageNumberLabel.setTitle((stateValue.currentPage + 1).description, for: .normal)
    }
    
    @objc func panedView(sender:UIPanGestureRecognizer){
        if (sender.state == UIGestureRecognizer.State.began) {
            startLocation = sender.location(in: self.view)
        } else if (sender.state == UIGestureRecognizer.State.ended) {
            let stopLocation = sender.location(in: self.view)
            let dx = stopLocation.x - startLocation.x
            //let dy = stopLocation.y - startLocation.y
            let distance = sqrt(dx * dx) //dy * dy) to include vertical distance
            print(stopLocation.x)
            print(startLocation.x)
            let isForward = (stopLocation.x - startLocation.x) < 0
            print("Distance: %f", distance)
            print("FORWARD " + isForward.description)
            if distance > swipeDistance {
                isForward ? setupNextPage() : setupPreviousPage()
            }
        }
    }
    
    private func shareApp() {
        let textToShare = "Check out Fairytale app"
        if let myWebsite = URL(string: "https://apps.apple.com/app/id1596570780") {
            let objectsToShare = [textToShare, myWebsite, UIImage(named: "bear-splash-1")!] as [Any]
            let activityVC = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
            /// Excluded Activities
            activityVC.excludedActivityTypes = [UIActivity.ActivityType.addToReadingList]
            if UIDevice.current.userInterfaceIdiom == .pad {
                popoverShare.isHidden = false
                activityVC.popoverPresentationController?.sourceView = popoverShare
                activityVC.popoverPresentationController?.sourceRect = popoverShare.frame
                activityVC.popoverPresentationController?.permittedArrowDirections = UIPopoverArrowDirection.down
                UIApplication.shared.windows.first?.rootViewController?.present(activityVC, animated: true, completion: nil)
            } else {
                self.present(activityVC, animated: true, completion: { [weak self] in
                    self?.popoverShare.isHidden = true
                })
            }
        }
    }
}
