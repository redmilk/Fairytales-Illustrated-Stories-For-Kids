//
//  AppDelegate.swift
//  Fairytales
//
//  Created by Danyl Timofeyev on 14.01.2022.
//

import UIKit
import CoreData
import ApphudSDK
import FacebookCore
import Firebase

private extension AppDelegate {
    func setupAnalyticsServices(_ application: UIApplication, _ launchOptions: [UIApplication.LaunchOptionsKey: Any]?) {
        _ = FacebookProvider(application: application,
                             launchOptions: launchOptions,
                             trackUserProperties: true,
                             settings: .auto)
    }
}

@main
class AppDelegate: UIResponder, UIApplicationDelegate, PurchesServiceProvidable {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        setupAnalyticsServices(application, launchOptions)
        ApplicationGlobalConfig().configure()
        // Apphud
        Apphud.start(apiKey: "app_YwLsuTLSmLBLd5Ew7498qEuPEA8Gqf")
        purchases.input.send(.congifure)
        // Facebook
        Settings.shared.isAdvertiserIDCollectionEnabled = true
        
        // Firebase
        FirebaseApp.configure()
        
        // orientation
        UIDevice.current.setValue(UIInterfaceOrientation.landscapeRight.rawValue, forKey: "orientation")
        UINavigationController.attemptRotationToDeviceOrientation()

        PurchesService.currentRandomFlag.toggle()
        
        return true
    }
    
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return .landscapeRight
    }
    
    func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool {
        ApplicationDelegate.shared.application(app, open: url,
            sourceApplication: options[UIApplication.OpenURLOptionsKey.sourceApplication] as? String,
            annotation: options[UIApplication.OpenURLOptionsKey.annotation])
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
}

