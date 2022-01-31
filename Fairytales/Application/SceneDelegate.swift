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

    func sceneDidDisconnect(_ scene: UIScene) { }

    func sceneDidBecomeActive(_ scene: UIScene) { }

    func sceneWillResignActive(_ scene: UIScene) { }

    func sceneWillEnterForeground(_ scene: UIScene) { }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.

        // Save changes in the application's managed object context when the application transitions to the background.
        (UIApplication.shared.delegate as? AppDelegate)?.saveContext()
    }


}

