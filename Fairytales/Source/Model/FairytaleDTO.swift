//
//  StoryModel.swift
//  Fairytales
//
//  Created by Danyl Timofeyev on 09.02.2022.
//

import Foundation

struct FairytaleDTO: Codable {
    let titles: [String: String]
    let annotation: [String: [String: String]]?
    let description: [String: String]?
    let default_title: String?
    let id_internal: String
    let pages: [PageModel]
    let image_ipad: String
    let image_iphone: String
    let storage_path: String
}
