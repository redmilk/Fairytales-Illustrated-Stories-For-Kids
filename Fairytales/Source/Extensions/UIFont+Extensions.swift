//
//  UIFont+Extensions.swift
//  Fairytales
//
//  Created by Danyl Timofeyev on 06.02.2022.
//

import Foundation

extension UIFont {
    static func getCustomFont(with title: String, of size: Int) -> UIFont { UIFont(name: title, size: CGFloat(size))! }
}
