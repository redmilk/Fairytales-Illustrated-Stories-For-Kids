//
//  PageModel.swift
//  Fairytales
//
//  Created by Danyl Timofeyev on 09.02.2022.
//

import Foundation

//struct PageModel: Codable {
//    let images: PageImages
//    let text: PageText
//    let page: Int
//
//
//}

struct PageModel: Codable {
    var images: PageImages
    var text: PageText
    var page: String
    
    private enum CodingKeys: String, CodingKey {
        case images, text, page
    }
    
    init(images: PageImages, text: PageText, page: String) {
        self.images = images
        self.text = text
        self.page = page
    }
    init(images: PageImages, text: PageText, page: Int) {
        self.images = images
        self.text = text
        self.page = page.description
    }
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        images = try container.decode(PageImages.self, forKey: .images)
        text = try container.decode(PageText.self, forKey: .text)
        do {
            page = try (container.decode(Int.self, forKey: .page)).description
        } catch DecodingError.typeMismatch {
            page = try (container.decode(String.self, forKey: .page))
        }
    }
}
