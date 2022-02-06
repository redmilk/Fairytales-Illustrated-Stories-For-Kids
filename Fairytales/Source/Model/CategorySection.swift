//
//  StorySection.swift
//  Fairytales
//
//  Created by Danyl Timofeyev on 24.01.2022.
//

import Foundation

final class CategorySection: Hashable, Comparable {
    let title: String
    let color: UIColor
    let thumbnail: UIImage
    let items: [StoryModel]
    
    init(title: String, color: UIColor, thumbnail: UIImage, items: [StoryModel] = []) {
        self.items = items
        self.title = title
        self.color = color
        self.thumbnail = thumbnail
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(items)
        hasher.combine(title)
        hasher.combine(color)
    }
    
    static func < (lhs: CategorySection, rhs: CategorySection) -> Bool {
        lhs.title < rhs.title
    }
    static func == (lhs: CategorySection, rhs: CategorySection) -> Bool {
        lhs.title == rhs.title && lhs.items == rhs.items && lhs.color == rhs.color
    }
}
