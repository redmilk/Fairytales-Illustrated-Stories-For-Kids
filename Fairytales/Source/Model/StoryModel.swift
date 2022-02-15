//
//  Model.swift
//  Fairytales
//
//  Created by Danyl Timofeyev on 06.02.2022.
//

import Foundation
import UIKit

final class StoryModel: Hashable, Comparable {
    
    enum State {
        case idle
        case selected
    }
    
    var title: String
    var state: State
    var assetThumbnail: String
    var imageThumbnail: UIImage? = nil
    var isHeartHidden: Bool
    var isFavorite: Bool
    
    var pages: [PageModel] = []
    var pagePictures: [UIImage] = []
    var pageText: [String] = []
    
    let id: String
    let colorForCategory: UIColor
    
    init(dto: FairytaleDTO) {
        let isIpad = UIDevice.current.isIPad
        let thumbnailPath = isIpad ? dto.image_ipad : dto.image_iphone
        title = dto.titles["ru"] ?? dto.default_title ?? "---"
        FirebaseClient.shared.storage.reference(withPath: dto.storage_path + thumbnailPath).downloadURL() { url, error in
            
        }
        assetThumbnail = ""
        isHeartHidden = false
        isFavorite = false
        state = .idle
        id = UUID().uuidString
        colorForCategory = .clear
        pages = dto.pages
    }
    
    init(title: String, thumbnail: String, state: State,
         isFavorite: Bool = false, isHeartHidden: Bool = true, id: String = UUID().uuidString, color: UIColor = .clear) {
        self.title = title
        self.state = state
        self.assetThumbnail = thumbnail
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
        lhs.assetThumbnail == rhs.assetThumbnail && lhs.title == rhs.title && lhs.state == rhs.state &&
        lhs.isHeartHidden == rhs.isHeartHidden && lhs.isFavorite == rhs.isFavorite && lhs.colorForCategory == rhs.colorForCategory &&
        rhs.pagePictures == lhs.pagePictures && rhs.pageText == lhs.pageText
    }
    func hash(into hasher: inout Hasher) {
        hasher.combine(title)
        hasher.combine(state)
        hasher.combine(assetThumbnail)
        hasher.combine(isHeartHidden)
        hasher.combine(isFavorite)
        hasher.combine(colorForCategory)
        hasher.combine(pagePictures)
        hasher.combine(pageText)
    }
}
