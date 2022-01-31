//
//  LifecyclePublishable.swift
//  Fairytales
//
//  Created by Danyl Timofeyev on 31.01.2022.
//

import Combine

enum Lifecycle {
    case viewDidLoad
    case viewWillAppear
    case viewDidAppear
    case viewWillDisappear
    case viewDidDisappear
}

protocol LifecycleTransmittable {
    var lifecycle: AnyPublisher<Lifecycle, Never> { get }
}
