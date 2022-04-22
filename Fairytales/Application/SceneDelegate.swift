//
//  SceneDelegate.swift
//  Fairytales
//
//  Created by Danyl Timofeyev on 14.01.2022.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    static var currentScene: UIScene?
    var window: UIWindow?
    var applicationCoordinator: ApplicationCoordinator!


    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let _ = (scene as? UIWindowScene) else { return }
        guard let windowScene = (scene as? UIWindowScene) else { return }
        SceneDelegate.currentScene = scene
        window = UIWindow(windowScene: windowScene)
        window!.makeKeyAndVisible()
        
        applicationCoordinator = ApplicationCoordinator(window: window!)
        applicationCoordinator.start()
    }
}

