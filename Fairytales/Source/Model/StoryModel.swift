//
//  Model.swift
//  Fairytales
//
//  Created by Danyl Timofeyev on 06.02.2022.
//

import Foundation

final class StoryModel: Hashable, Comparable {
    
    enum State {
        case idle
        case selected
    }
    
    var title: String
    var state: State
    var thumbnail: String
    var isHeartHidden: Bool
    var isFavorite: Bool
    let id: String
    let colorForCategory: UIColor
    
    init(title: String, thumbnail: String, state: State,
         isFavorite: Bool = false, isHeartHidden: Bool = true, id: String = UUID().uuidString, color: UIColor = .clear) {
        self.title = title
        self.state = state
        self.thumbnail = thumbnail
        self.isFavorite = isFavorite
        self.isHeartHidden = isHeartHidden
        self.id = id
        self.colorForCategory = color
    }
    
    // comparable
    static func < (lhs: StoryModel, rhs: StoryModel) -> Bool {
        lhs.title < rhs.title
    }
    // hashable
    static func == (lhs: StoryModel, rhs: StoryModel) -> Bool {
        lhs.thumbnail == rhs.thumbnail && lhs.title == rhs.title && lhs.state == rhs.state &&
        lhs.isHeartHidden == rhs.isHeartHidden && lhs.isFavorite == rhs.isFavorite && lhs.colorForCategory == rhs.colorForCategory
    }
    func hash(into hasher: inout Hasher) {
        hasher.combine(title)
        hasher.combine(state)
        hasher.combine(thumbnail)
        hasher.combine(isHeartHidden)
        hasher.combine(isFavorite)
        hasher.combine(colorForCategory)
    }
}
