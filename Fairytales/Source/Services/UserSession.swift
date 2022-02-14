//
//  File.swift
//  AirPrint
//
//  Created by Danyl Timofeyev on 29.11.2021.
//

import Foundation
import Combine

final class UserSession {
    enum Event {
        case addFavorite(StoryModel)
    }
    enum Response { }
    var input = PassthroughSubject<Event, Never>()
    var output = PassthroughSubject<Response, Never>()
    private var bag = Set<AnyCancellable>()

    var categories: Set<CategorySection> = []
    var isBoy: Bool = true
    var isIpad: Bool = UIDevice.current.isIPad
    var locale: String = "en"
    
    //var favoritesCount: Int { stories.filter { $0.isFavorite == true }.count }
    var selectedCategory: CategorySection!
    var selectedStory: StoryModel!// = StoryModel(title: "Рапунцель 3", thumbnail: "story-thumbnail-1", state: .idle, isHeartHidden: false)

    init() {
        input.sink(receiveValue: { [weak self] event in
            guard let self = self else { return }
            switch event {
            case .addFavorite(let model):
                model.isFavorite = true
                //self.stories.update(with: model)
            }
        })
        .store(in: &bag)
    }
}
