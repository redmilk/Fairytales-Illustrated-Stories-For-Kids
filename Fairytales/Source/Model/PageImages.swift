//
//  PageImages.swift
//  Fairytales
//
//  Created by Danyl Timofeyev on 09.02.2022.
//

import Foundation

struct PageImages: Codable {
    let boy_ipad: String
    let boy_iphone: String
    let girl_ipad: String
    let girl_iphone: String
    
    func getImagePath(boy: Bool, ipad: Bool) -> String {
        if ipad {
            if boy {
                return boy_ipad
            } else {
                return girl_ipad
            }
        } else {
            if boy {
                return boy_iphone
            } else {
                return girl_iphone
            }
        }
    }
}
