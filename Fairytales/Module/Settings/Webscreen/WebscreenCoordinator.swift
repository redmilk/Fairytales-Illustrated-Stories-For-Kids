//
//  
//  WebscreenCoordinator.swift
//  Fairytales
//
//  Created by Danyl Timofeyev on 26.01.2022.
//
//

import Foundation
import UIKit.UINavigationController
import Combine

protocol WebscreenCoordinatorProtocol {
   
}

final class WebscreenCoordinator: Coordinatable, WebscreenCoordinatorProtocol {
    var navigationController: UINavigationController?
    private let contentType: WebscreenViewController.Content
    
    init(navigationController: UINavigationController?, contentType: WebscreenViewController.Content) {
        self.navigationController = navigationController
        self.contentType = contentType
    }
    deinit {
        Logger.log(String(describing: self), type: .deinited)
    }
    
    func start() {
        let viewModel = WebscreenViewModel(coordinator: self, contentType: contentType)
        let controller = WebscreenViewController(viewModel: viewModel)
        navigationController?.pushViewController(controller, animated: true)
    }
    
    func end() {

    }
}
