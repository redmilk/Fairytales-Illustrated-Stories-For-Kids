//
//  StoryTextFormatter.swift
//  Fairytales
//
//  Created by Danyl Timofeyev on 21.02.2022.
//

import Foundation

fileprivate let kNameKey = "{{Name}}"
fileprivate let kNewlineKey = "//"

struct StoryTextFormatter: UserSessionServiceProvidable {
    static let shared = StoryTextFormatter()
    private var name: String { userSession.kidName }
    
    func preparePageText(_ text: String) -> String {
        return text.replacingOccurrences(of: kNameKey, with: name)
    }
}
