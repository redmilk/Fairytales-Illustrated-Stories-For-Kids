//
//  CategorySection.swift
//  Fairytales
//
//  Created by Danyl Timofeyev on 24.01.2022.
//

import Foundation

final class CategorySection: Hashable {
    var id: String?
    let title: String
    let items: [CategorySectionItem]
    
    init(items: [CategorySectionItem], title: String) {
        self.items = items
        self.title = title
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(items)
        hasher.combine(title)
        hasher.combine(id)
    }

    static func == (lhs: CategorySection, rhs: CategorySection) -> Bool {
        lhs.title == rhs.title && lhs.items == rhs.items && lhs.id == rhs.id
    }
}
