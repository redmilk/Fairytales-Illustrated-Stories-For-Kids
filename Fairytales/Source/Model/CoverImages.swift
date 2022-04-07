//
//  CoverImages.swift
//  Fairytales
//
//  Created by Danyl Timofeyev on 07.04.2022.
//

import Foundation

struct CoverImages: Codable {
    var ipadBoy: String
    var ipadGirl: String
    var iphoneBoy: String
    var iphoneGirl: String
    
    private enum CodingKeys: String, CodingKey {
        case ipadBoy = "boy_ipad"
        case ipadGirl = "girl_ipad"
        case iphoneBoy = "boy_iphone"
        case iphoneGirl = "girl_iphone"
    }
    
//    init(images: PageImages, text: PageText, page: String) {
//        self.images = images
//        self.text = text
//        self.page = page
//    }
//    init(images: PageImages, text: PageText, page: Int) {
//        self.images = images
//        self.text = text
//        self.page = page.description
//    }
//    init(from decoder: Decoder) throws {
//        let container = try decoder.container(keyedBy: CodingKeys.self)
//        images = try container.decode(PageImages.self, forKey: .images)
//        text = try container.decode(PageText.self, forKey: .text)
//        do {
//            page = try (container.decode(Int.self, forKey: .page)).description
//        } catch DecodingError.typeMismatch {
//            page = try (container.decode(String.self, forKey: .page))
//        }
//    }
}
