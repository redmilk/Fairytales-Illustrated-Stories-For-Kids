//
//  PageText.swift
//  Fairytales
//
//  Created by Danyl Timofeyev on 09.02.2022.
//

import Foundation

struct PageText: Codable {
    let default_text: String
    let boy: [String: String]
    let girl: [String: String]
    
    func getText(boy: Bool, locale: String) -> String {
        if boy {
            return self.boy[locale] ?? default_text
        } else {
            return self.girl[locale] ?? default_text
        }
    }
}
