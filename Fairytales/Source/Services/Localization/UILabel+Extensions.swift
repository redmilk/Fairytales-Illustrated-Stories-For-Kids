//
//  UILabel+Extensions.swift
//  Fairytales
//
//  Created by Danyl Timofeyev on 31.01.2022.
//

import UIKit.UILabel

extension UILabel {
    
    var fbString: LocalizedStringID? {
        set {
            guard newValue != nil else { return }
            text = LocalizedString.string(forId: newValue!)
        }
        get {
            return nil
        }
    }
    
    // attribute storyaboard control
    @IBInspectable var _LocalizedStringID: String {
        set {
            var dictFromFirestore: [String: Any]?
            guard let localizationDict = dictFromFirestore else { return text = newValue }
            if let value = localizationDict[newValue] as? String {
                return text = value
            }
            text = newValue.uppercased()
        }
        get { return text ?? "" }
    }

}
