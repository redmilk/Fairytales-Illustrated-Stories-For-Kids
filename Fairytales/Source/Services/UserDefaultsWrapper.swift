//
//  UserDefaultsWrapper.swift
//  Fairytales
//
//  Created by Danyl Timofeyev on 22.02.2022.
//

import Foundation

enum UDK: String, CaseIterable { // UDK - User Defaults Keys
    case kidName, kidGender, locale, favoritesCounter
}

@propertyWrapper struct UD<Value: Codable> { // UD - User Defaults
    private let key: UDK
    private let defaultValue: Value
    private let ud: UserDefaults = .standard
    
    init(_ key: UDK, _ defaultValue: Value) {
        self.key = key
        self.defaultValue = defaultValue
    }
    
    var wrappedValue: Value {
        get {
            if let data = ud.value(forKey: key.rawValue) as? Data,
               let dict = try? PropertyListDecoder().decode([Value].self, from: data) {
                return dict.first!
            }
            return defaultValue
        }
        set {
            //we need to wrap it into an array to encode Bool or String etc. to Data
            let value = try? PropertyListEncoder().encode([newValue])
            ud.setValue(value, forKey: key.rawValue)
        }
    }
}
