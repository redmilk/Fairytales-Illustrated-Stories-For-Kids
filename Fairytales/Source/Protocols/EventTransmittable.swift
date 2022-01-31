//
//  EventTransmittable.swift
//  Fairytales
//
//  Created by Danyl Timofeyev on 31.01.2022.
//

import Combine

protocol EventTransmittable {
    var output: AnyPublisher<EventRepresentable, Never> { get }
}
