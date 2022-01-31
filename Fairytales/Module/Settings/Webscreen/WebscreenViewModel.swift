//
//  
//  WebscreenViewModel.swift
//  Fairytales
//
//  Created by Danyl Timofeyev on 26.01.2022.
//
//

import Foundation
import Combine


final class WebscreenViewModel {
    enum Action {
        case requestState
    }
    
    let input = PassthroughSubject<Action, Never>()
    let output = PassthroughSubject<WebscreenViewController.State, Never>()
    
    private let coordinator: WebscreenCoordinator & Coordinatable
    private var bag = Set<AnyCancellable>()
    private let contentType: WebscreenViewController.Content

    init(coordinator: WebscreenCoordinator & Coordinatable, contentType: WebscreenViewController.Content) {
        self.coordinator = coordinator
        self.contentType = contentType
        dispatchActions()
    }
    deinit {
        Logger.log(String(describing: self), type: .deinited)
    }
}

// MARK: - Internal

private extension WebscreenViewModel {
    /// Handle ViewController's actions
    private func dispatchActions() {
        input.sink(receiveValue: { [weak self] action in
            guard let self = self else { return }
            switch action {
            case .requestState:
                self.output.send(.configure(contentType: self.contentType))
            }
        })
        .store(in: &bag)
    }
}

