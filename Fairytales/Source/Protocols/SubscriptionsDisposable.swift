//
//  SubscriptionsDisposable.swift
//  Fairytales
//
//  Created by Danyl Timofeyev on 31.01.2022.
//

import Combine

protocol SubscriptionsDisposable {
    var bag: Set<AnyCancellable> { get set }
}
