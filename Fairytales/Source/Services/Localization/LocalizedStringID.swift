//
//  LocalizedStringID.swift
//  Fairytales
//
//  Created by Danyl Timofeyev on 31.01.2022.
//

import Foundation
import UIKit

enum LocalizedStringID: String {
    //MARK: Oboarding
    case buttonContinue = "onboarding_button_continue"
    case buttonSkip = "onboarding_button_skip"
    
    //MARK: Subscriptions
   
    //MARK: First setup settings
    
    //MARK: Categories
    
    //MARK: Story selection
    
    //MARK: Story item
   
    //MARK: Settings
    
    //MARK: Manage subscriptions
   
    //MARK: Other
}

final class LocalizedString {
    static func string(forId id: LocalizedStringID, args: [CVarArg]? = nil) -> String {
        let dictFromFirebase = [String: Any]()
        var choosenLanguagePreference: String = "en"
        let languageSubrangeDict = dictFromFirebase[id.rawValue] as? [String: Any]
        return (languageSubrangeDict?[choosenLanguagePreference] as? String) ?? ""
    }
}
