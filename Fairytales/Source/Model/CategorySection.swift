//
//  StorySection.swift
//  Fairytales
//
//  Created by Danyl Timofeyev on 24.01.2022.
//

import Foundation

final class CategorySection: Hashable, Comparable {
    let title: String
    let description: String
    let color: UIColor
    let thumbnail: UIImage
    let category: CategoryPath
    let items: [StoryModel]
    
    init(title: String, description: String, color: UIColor, thumbnail: UIImage, items: [StoryModel], category: CategoryPath) {
        self.items = items
        self.title = title
        self.description = description
        self.color = color
        self.thumbnail = thumbnail
        self.category = category
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(items)
        hasher.combine(title)
        hasher.combine(color)
        hasher.combine(category)
        hasher.combine(description)
    }
    
    static func < (lhs: CategorySection, rhs: CategorySection) -> Bool {
        lhs.title < rhs.title
    }
    static func == (lhs: CategorySection, rhs: CategorySection) -> Bool {
        lhs.title == rhs.title && lhs.items == rhs.items && lhs.color == rhs.color
    }
}
