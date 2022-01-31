//
//  ViewController.swift
//  Fairytales
//
//  Created by Danyl Timofeyev on 31.01.2022.
//

import Combine
import UIKit

// MARK: - Capabilities

/// events in/out, state management, disposable
extension BaseViewController: SubscriptionsDisposable, EventsAcceptable,
                                EventTransmittable, LifecycleTransmittable { }

/// alerts presentation, loading activity, navigation
extension BaseViewController: AlertPresentable, ActivityIndicatorPresentable, CoordinatorPreservable { }

class BaseViewController: UIViewController {
    // API
    var input = PassthroughSubject<EventRepresentable, Never>()
    var output: AnyPublisher<EventRepresentable, Never> { _output.eraseToAnyPublisher() }
    var lifecycle: AnyPublisher<Lifecycle, Never> { _lifecycle.eraseToAnyPublisher() }
    var bag = Set<AnyCancellable>()
    
    var coordinator: Coordinatable
    
    // Overrides
    func configure() { }
    func applyStyling() { }
    func handleEvents() { }
    func handleState() { }
    
    private var _output = PassthroughSubject<EventRepresentable, Never>()
    private var _lifecycle = PassthroughSubject<Lifecycle, Never>()
    deinit { Logger.log(String(describing: self), type: .deinited) }
    
    init(coordinator: Coordinatable, type: BaseViewController.Type) {
        self.coordinator = coordinator
        super.init(nibName: String(describing: type), bundle: nil)
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        _lifecycle.send(.viewDidLoad)
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        _lifecycle.send(.viewWillAppear)
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        _lifecycle.send(.viewDidAppear)
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        _lifecycle.send(.viewWillDisappear)
    }
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        _lifecycle.send(.viewDidDisappear)
    }
}
