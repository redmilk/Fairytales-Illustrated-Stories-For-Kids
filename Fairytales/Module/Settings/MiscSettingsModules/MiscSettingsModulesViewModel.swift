//
//  
//  MiscSettingsModulesViewModel.swift
//  AirPrint
//
//  Created by Danyl Timofeyev on 16.12.2021.
//
//

import Foundation
import Combine

final class MiscSettingsModulesViewModel {
    enum Action {
        case requestState
    }
    
    let input = PassthroughSubject<MiscSettingsModulesViewModel.Action, Never>()
    let output = PassthroughSubject<MiscSettingsModulesViewController.State, Never>()
    
    private let coordinator: MiscSettingsModulesCoordinatorProtocol & Coordinatable
    private var bag = Set<AnyCancellable>()
    private let isPrivacyPolicy: Bool

    init(coordinator: MiscSettingsModulesCoordinatorProtocol & Coordinatable, isPrivacyPolicy: Bool) {
        self.coordinator = coordinator
        self.isPrivacyPolicy = isPrivacyPolicy
        dispatchActions()
    }
    deinit {
        Logger.log(String(describing: self), type: .deinited)
    }
}

// MARK: - Internal

private extension MiscSettingsModulesViewModel {
    
    /// Handle ViewController's actions
    private func dispatchActions() {
        input.sink(receiveValue: { [weak self] action in
            guard let self = self else { return }
            switch action {
            case .requestState:
                self.output.send(.configure(isPrivacyPolicy: self.isPrivacyPolicy))
            }
        })
        .store(in: &bag)
    }
}
