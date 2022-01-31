//
//  ___FILEHEADER___
//

import Foundation
import Combine

final class ___VARIABLE_productName:identifier___ViewModel {
    enum Action {
        case dummyAction
    }
    
    let input = PassthroughSubject<___VARIABLE_productName:identifier___ViewModel.Action, Never>()
    let output = PassthroughSubject<___VARIABLE_productName:identifier___ViewController.State, Never>()
    
    private let coordinator: ___VARIABLE_productName:identifier___CoordinatorProtocol & Coordinatable
    private var bag = Set<AnyCancellable>()

    init(coordinator: ___VARIABLE_productName:identifier___CoordinatorProtocol & Coordinatable) {
        self.coordinator = coordinator
        handleActions()
    }
    deinit {
        Logger.log(String(describing: self), type: .deinited)
    }
}

// MARK: - Private

private extension ___VARIABLE_productName:identifier___ViewModel {
    
    private func handleActions() {
        input.sink(receiveValue: { [weak self] action in
            switch action {
            case .dummyAction:
                break
            }
        })
        .store(in: &bag)
    }
}
