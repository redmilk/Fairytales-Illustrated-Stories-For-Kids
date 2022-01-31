//
//  
//  StorySelectViewModel.swift
//  Fairytales
//
//  Created by Danyl Timofeyev on 31.01.2022.
//
//

import Foundation
import Combine

final class StorySelectViewModel {
    enum Action {
        case dummyAction
    }
    
    let input = PassthroughSubject<StorySelectViewModel.Action, Never>()
    let output = PassthroughSubject<StorySelectViewController.State, Never>()
    
    private let coordinator: StorySelectCoordinatorProtocol & Coordinatable
    private var bag = Set<AnyCancellable>()

    init(coordinator: StorySelectCoordinatorProtocol & Coordinatable) {
        self.coordinator = coordinator
        dispatchActions()
    }
    deinit {
        Logger.log(String(describing: self), type: .deinited)
    }
}

// MARK: - Internal

private extension StorySelectViewModel {
    
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
