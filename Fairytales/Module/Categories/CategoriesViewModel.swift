//
//  
//  CategoriesViewModel.swift
//  Fairytales
//
//  Created by Danyl Timofeyev on 14.01.2022.
//
//

import Foundation
import Combine

final class CategoriesViewModel {
    enum Event {
    }
    
    let input = PassthroughSubject<Event, Never>()
    let output = PassthroughSubject<Event, Never>()
    
    private let coordinator: CategoriesCoordinatorProtocol & Coordinatable
    private var bag = Set<AnyCancellable>()

    init(coordinator: CategoriesCoordinatorProtocol & Coordinatable) {
        self.coordinator = coordinator
        dispatchActions()
    }
    deinit {
        Logger.log(String(describing: self), type: .deinited)
    }
}

// MARK: - Internal

private extension CategoriesViewModel {
    
    /// Handle ViewController's actions
    private func dispatchActions() {
        input.sink(receiveValue: { [weak self] action in
//            switch action {
//            case .dummyAction:
//                break
//            }
        })
        .store(in: &bag)
    }
}
