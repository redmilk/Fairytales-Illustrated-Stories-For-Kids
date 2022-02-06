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
      
    }
}

// MARK: - StorySelectViewController

final class StoryViewController: BaseViewController, UserSessionServiceProvidable {
    enum Buttons {
        case heart, home, prevPage, nextPage
    }
            
    @IBOutlet weak var homeButton: BaseButton!
    @IBOutlet weak var favoritesButton: BaseButton!
    @IBOutlet weak var previousPageButton: BaseButton!
    @IBOutlet weak var nextPageButton: BaseButton!
    
    private var stateValue: State { state.value as! State }

    init(coordinator: Coordinatable, selectedStory: StoryModel) {
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
                    break
                case .nextPage: break
                }
            }).store(in: &bag)
    }
}
