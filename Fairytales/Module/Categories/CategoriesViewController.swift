//
//  
//  CategoriesViewController.swift
//  Fairytales
//
//  Created by Danyl Timofeyev on 14.01.2022.
//
//

import UIKit
import Combine

// MARK: - CategoriesViewController

final class CategoriesViewController: UIViewController {
    enum State {
        case dummyState
    }
        
    private let viewModel: CategoriesViewModel
    private var bag = Set<AnyCancellable>()
    
    init(viewModel: CategoriesViewModel) {
        self.viewModel = viewModel
        super.init(nibName: String(describing: CategoriesViewController.self), bundle: nil)
        /**
         CONNECT FILE'S OWNER TO SUPERVIEW IN XIB FILE
         CONNECT FILE'S OWNER TO SUPERVIEW IN XIB FILE
         CONNECT FILE'S OWNER TO SUPERVIEW IN XIB FILE
         */
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    deinit {
        Logger.log(String(describing: self), type: .deinited)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        handleStates()
    }
}

// MARK: - Internal

private extension CategoriesViewController {
    
    /// Handle ViewModel's states
    func handleStates() {
        viewModel.output.sink(receiveValue: { [weak self] state in
            
        })
        .store(in: &bag)
    }
}
