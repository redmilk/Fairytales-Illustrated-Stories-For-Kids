//
//  CategoryModel.swift
//  Fairytales
//
//  Created by Danyl Timofeyev on 13.02.2022.
//

import Foundation

struct CategoryDTO: Codable {
    let image_ipad: String
    let image_iphone: String
    let id_internal: String
    let default_title: String
    let titles: [String: String]
}
