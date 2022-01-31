//
//  
//  SubscriptionViewModel.swift
//  Fairytales
//
//  Created by Danyl Timofeyev on 14.01.2022.
//
//

import Foundation
import Combine

final class SubscriptionViewModel {
    enum Action {
        case dummyAction
    }
    
    let input = PassthroughSubject<SubscriptionViewModel.Action, Never>()
    let output = PassthroughSubject<SubscriptionViewController.State, Never>()
    
    private let coordinator: SubscriptionCoordinatorProtocol & Coordinatable
    private var bag = Set<AnyCancellable>()

    init(coordinator: SubscriptionCoordinatorProtocol & Coordinatable) {
        self.coordinator = coordinator
        dispatchActions()
    }
    deinit {
        Logger.log(String(describing: self), type: .deinited)
    }
}

// MARK: - Internal

private extension SubscriptionViewModel {
    
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
