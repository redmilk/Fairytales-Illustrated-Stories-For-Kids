//
//  PageText.swift
//  Fairytales
//
//  Created by Danyl Timofeyev on 09.02.2022.
//

import Foundation

struct PageText: Codable {
    let default_text: String?
    let boy: [String: String]
    let girl: [String: String]
    
    func getText(boy: Bool, locale: String) -> String {
        var text = ""
        text = StoryTextFormatter.shared.preparePageTextNameReplacement((boy ? self.boy[locale] : self.girl[locale]) ?? default_text ?? "---")
        text = StoryTextFormatter.shared.preparePageTextNewLinesReplacement(text)
        return text
    }
}
