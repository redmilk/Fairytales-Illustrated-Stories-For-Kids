//
//  
//  SettingsViewController.swift
//  Fairytales
//
//  Created by Danyl Timofeyev on 14.01.2022.
//
//

import UIKit
import Combine


extension SettingsViewController {
    class State: BaseState {
      
    }
}

// MARK: - StorySelectViewController

final class SettingsViewController: BaseViewController {
    enum Buttons {
        case back, heart
    }
            
    @IBOutlet weak var backButton: BaseButton!
    @IBOutlet weak var favoritesButton: BaseButton!
    
    private var stateValue: State { state.value as! State }

    init(coordinator: Coordinatable) {
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
        // buttons
        Publishers.MergeMany(
            backButton.tapPublisher.map { _ in Buttons.back },
            favoritesButton.tapPublisher.map { _ in Buttons.heart })
            .sink(receiveValue: { [weak self] button in
                guard let self = self else { return }
                switch button {
                case .back: self.coordinator.end()
                case .heart:
                    break
                }
            }).store(in: &bag)
    }
}
