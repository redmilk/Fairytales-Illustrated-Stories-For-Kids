//
//  Constants.swift
//  AirPrint
//
//  Created by Danyl Timofeyev on 04.12.2021.
//

import UIKit.UIImage

let POINTS_PER_INCH: CGFloat = 72 /// UI points per 1 inch of paper

enum Constants {
    static let menuItemHeight: CGFloat = UIScreen.main.bounds.height * 0.33
    static let menuItemWidth: CGFloat = UIScreen.main.bounds.width * 0.28
    static let storyThumbnailPlaceholder = UIImage(named: "bear-splash-1")!
}
