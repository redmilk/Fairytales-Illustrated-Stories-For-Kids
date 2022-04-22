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
    var isBoy: Bool { kidActor == .boy }
    var isIpad: Bool = UIDevice.current.isIPad
    
    @UD(.locale, "ru")
    var locale: String
    @UD(.kidName, "")
    var kidName: String
    @UD(.kidGender, .boy)
    var kidActor: KidActor
    @UD(.favoritesCounter, 0)
    var favoritesCounter: Int
    
    var selectedCategory: CategorySection!    
    var selectedStory: StoryModel!

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
    
    var pagesTotalNumber: Int { selectedStory.pages.count }

    var currentPageNumber: Int {
        let storyId = selectedStory.dto.id_internal
        return (UserDefaults.standard.object(forKey: storyId + "page") as? Int) ?? 0
    }
    
    func saveCurrentPageOfSelectedStory(_ currentPage: Int) {
        let storyId = selectedStory.dto.id_internal
        UserDefaults.standard.set(currentPage, forKey: storyId + "page")
    }
    
    // Favorites
    func checkIsStoryFavorite(with internalID: String) -> Bool {
        guard let favoritesIDList = UserDefaults.standard.value(forKey: "favorites") as? [String],
              let _ = favoritesIDList.firstIndex(where: { $0 == internalID }) else { return false }
        return true
    }
    @discardableResult
    func toggleFavorites(with internalID: String) -> (Bool, Int) {
        if var favoritesIDList = UserDefaults.standard.value(forKey: "favorites") as? [String] {
            if let index = favoritesIDList.firstIndex(where: { $0 == internalID }) {
                let deletedFromFavorites = favoritesIDList.remove(at: index)
                UserDefaults.standard.set(favoritesIDList, forKey: "favorites")
                favoritesCounter = favoritesIDList.count
                return (false, favoritesIDList.count)
            } else {
                favoritesIDList.append(internalID)
                UserDefaults.standard.set(favoritesIDList, forKey: "favorites")
                favoritesCounter = favoritesIDList.count
                return (true, favoritesIDList.count)
            }
        } else {
            let newList = [internalID]
            UserDefaults.standard.set(newList, forKey: "favorites")
            favoritesCounter = 1
            return (true, 1)
        }
    }
    
    // Persistance status
    func checkIsStoryPersistedInStorage(with internalID: String) -> Bool {
        guard let persistance = UserDefaults.standard.value(forKey: "persistance") as? [String],
              let _ = persistance.firstIndex(where: { $0 == internalID }) else { return false }
        return true
    }
    
    func setStoryPersistanceStatusOn(with internalID: String) {
        if var persistanceIDList = UserDefaults.standard.value(forKey: "persistance") as? [String] {
            if let index = persistanceIDList.firstIndex(where: { $0 == internalID }) {
                // story id already persist
            } else {
                persistanceIDList.append(internalID)
                UserDefaults.standard.set(persistanceIDList, forKey: "persistance")
            }
        } else {
            let newList = [internalID]
            UserDefaults.standard.set(newList, forKey: "persistance")
        }
    }
}
