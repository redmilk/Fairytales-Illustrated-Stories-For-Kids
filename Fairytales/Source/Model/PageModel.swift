//
//  PageModel.swift
//  Fairytales
//
//  Created by Danyl Timofeyev on 09.02.2022.
//

import Foundation

struct PageModel: Codable {
    let images: PageImages
    let text: PageText
    let page: Int
}
