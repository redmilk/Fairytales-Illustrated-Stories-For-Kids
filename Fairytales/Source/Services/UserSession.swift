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

    var categories: Set<CategorySection> = [
        CategorySection(title: "Терапевтическая", color: ColorPalette.categoryDarkRed, thumbnail: UIImage(named: "categorie-thumbnail-2")!),
        CategorySection(title: "Обучающая", color: ColorPalette.categoryDarkGreen, thumbnail: UIImage(named: "categorie-thumbnail-1")!),
        CategorySection(title: "Тихая", color: ColorPalette.categoryDarkBlue, thumbnail: UIImage(named: "categorie-thumbnail-3")!),
    ]
    
    var stories: Set<StoryModel> = [
        StoryModel(title: "Рапунцель", thumbnail: "story-thumbnail-1", state: .idle, isHeartHidden: false),
        StoryModel(title: "Тысяча и одна ночь", thumbnail: "story-thumbnail-2", state: .selected, isHeartHidden: false),
        StoryModel(title: "Белоснежка и семь гномов", thumbnail: "story-thumbnail-3", state: .idle, isHeartHidden: false),
        StoryModel(title: "Рапунцель 2", thumbnail: "story-thumbnail-1", state: .idle, isHeartHidden: false),
        StoryModel(title: "Тысяча и одна ночь 2", thumbnail: "story-thumbnail-2", state: .idle, isHeartHidden: false),
        StoryModel(title: "Белоснежка и семь гномов 2", thumbnail: "story-thumbnail-3", state: .idle, isHeartHidden: false),
        StoryModel(title: "Рапунцель 3", thumbnail: "story-thumbnail-1", state: .idle, isHeartHidden: false),
        StoryModel(title: "Тысяча и одна ночь 3", thumbnail: "story-thumbnail-2", state: .idle, isHeartHidden: false),
        StoryModel(title: "Белоснежка и семь гномов 3", thumbnail: "story-thumbnail-3", state: .idle, isHeartHidden: false),
    ]
    
    var favoritesCount: Int { stories.filter { $0.isFavorite == true }.count }
    var selectedCategory: CategorySection!
    var selectedStory: StoryModel = StoryModel(title: "Рапунцель 3", thumbnail: "story-thumbnail-1", state: .idle, isHeartHidden: false)

    init() {
        input.sink(receiveValue: { [weak self] event in
            guard let self = self else { return }
            switch event {
            case .addFavorite(let model):
                model.isFavorite = true
                self.stories.update(with: model)
            }
        })
        .store(in: &bag)
    }
}
