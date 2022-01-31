//
//  
//  StoryViewModel.swift
//  Fairytales
//
//  Created by Danyl Timofeyev on 14.01.2022.
//
//

import Foundation
import Combine

final class StoryViewModel {
    enum Action {
        case dummyAction
    }
    
    let input = PassthroughSubject<StoryViewModel.Action, Never>()
    let output = PassthroughSubject<StoryViewController.State, Never>()
    
    private let coordinator: StoryCoordinatorProtocol & Coordinatable
    private var bag = Set<AnyCancellable>()

    init(coordinator: StoryCoordinatorProtocol & Coordinatable) {
        self.coordinator = coordinator
        dispatchActions()
    }
    deinit {
        Logger.log(String(describing: self), type: .deinited)
    }
}

// MARK: - Internal

private extension StoryViewModel {
    
    /// Handle ViewController's actions
    private func dispatchActions() {
        input.sink(receiveValue: { [weak self] action in
            switch action {
            case .dummyAction:
                break
            }
        })
        .store(in: &bag)
    }
}
