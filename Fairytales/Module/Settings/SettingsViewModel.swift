//
//  
//  SettingsViewModel.swift
//  Fairytales
//
//  Created by Danyl Timofeyev on 14.01.2022.
//
//

import Foundation
import Combine

final class SettingsViewModel {
    enum Action {
        case dummyAction
    }
    
    let input = PassthroughSubject<SettingsViewModel.Action, Never>()
    let output = PassthroughSubject<SettingsViewController.State, Never>()
    
    private let coordinator: SettingsCoordinatorProtocol & Coordinatable
    private var bag = Set<AnyCancellable>()

    init(coordinator: SettingsCoordinatorProtocol & Coordinatable) {
        self.coordinator = coordinator
        dispatchActions()
    }
    deinit {
        Logger.log(String(describing: self), type: .deinited)
    }
}

// MARK: - Internal

private extension SettingsViewModel {
    
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
