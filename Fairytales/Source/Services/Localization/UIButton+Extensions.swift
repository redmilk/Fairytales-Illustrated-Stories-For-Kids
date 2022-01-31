//
//  UIButton+Extensions.swift
//  Fairytales
//
//  Created by Danyl Timofeyev on 31.01.2022.
//

import Foundation
import UIKit

extension UIButton {
    
    @IBInspectable var _LocalizedStringID: String {
        set {
            let label = UILabel()
            label._LocalizedStringID = newValue
            setTitle(label.text, for: .normal)
        }
        get { return "" }
    }
    
}


