//
//  Set+Extensions.swift
//  Fairytales
//
//  Created by Danyl Timofeyev on 06.02.2022.
//

import Foundation

extension Set {
    var toArray: [Element] { Array(self) }
}

extension Set where Element: Comparable {
    var toSortedArray: [Element] { self.toArray.sorted() }
}
