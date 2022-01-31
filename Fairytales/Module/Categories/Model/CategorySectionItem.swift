//
//  StorySection.swift
//  Fairytales
//
//  Created by Danyl Timofeyev on 14.01.2022.
//

import UIKit

final class CategorySectionItem: Hashable, Equatable {
    let id: String
    var image: UIImage
    var text: String?
    
    init(id: String, image: UIImage, text: String) {
        self.id = id
        self.image = image
        self.text = text
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(image)
        hasher.combine(text)
    }
    
    static func == (lhs: CategorySectionItem, rhs: CategorySectionItem) -> Bool {
        lhs.id == rhs.id && lhs.text == rhs.text && lhs.image == rhs.image
    }
}
