//
//  ServicesContainer.swift
//  AirPrint
//
//  Created by Danyl Timofeyev on 27.11.2021.
//

import UIKit.UIApplication

fileprivate let services = ServicesContainer()

final class ServicesContainer {
    lazy var userSession: UserSession = UserSession()
    var imageDownloader: ImageLoader = ImageLoader()
    var purchases: PurchesService = PurchesService()
}

// MARK: - add specific service dependency to object


protocol AnalyticServiceProvider {
    var analytics: AnalyticsService { get }
}
extension AnalyticServiceProvider {
    var analytics: AnalyticsService {
        return (UIApplication.shared.delegate as! AppDelegate).analytics
    }
}

/// Purchase Service
protocol PurchesServiceProvidable { }
extension PurchesServiceProvidable {
    var purchases: PurchesService { services.purchases }
}

/// User Session Service
protocol UserSessionServiceProvidable { }
extension UserSessionServiceProvidable {
    var userSession: UserSession { services.userSession }
}

/// Image downloader
protocol ImageDownloaderProvidable { }
extension ImageDownloaderProvidable {
    var imageDownloader: ImageLoader { services.imageDownloader }
}

// MARK: - if you want to include all services to object

/// All services
protocol AllServicesProvidable { }
extension AllServicesProvidable {
    var allServices: ServicesContainer { services }
}
