//
//  ApplicationGlobalConfig.swift
//  AirPrint
//
//  Created by Danyl Timofeyev on 23.11.2021.
//

import UIKit
import KingfisherWebP
import Kingfisher

struct ApplicationGlobalConfig {
    func configure() {
        UINavigationBar.appearance().setBackgroundImage(UIImage(), for: .default)
        UINavigationBar.appearance().shadowImage = UIImage()
        UINavigationBar.appearance().isTranslucent = true

        // Cache settings
        //
        // WebP images
        KingfisherManager.shared.defaultOptions += [
          .processor(WebPProcessor.default),
          .cacheSerializer(WebPSerializer.default)
        ]

       
    }
}
