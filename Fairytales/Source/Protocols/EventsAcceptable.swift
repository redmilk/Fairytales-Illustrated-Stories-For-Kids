//
//  EventsAcceptable.swift
//  Fairytales
//
//  Created by Danyl Timofeyev on 31.01.2022.
//

import Combine

protocol EventsAcceptable {
    var input: PassthroughSubject<EventRepresentable, Never> { get }
}
