//
//  File.swift
//  AirPrint
//
//  Created by Danyl Timofeyev on 29.11.2021.
//

import Foundation
import Combine

final class UserSession {
    enum Action {
       
    }
    
    enum Response {
    
    }
    
    var input = PassthroughSubject<Action, Never>()
    var output = PassthroughSubject<Response, Never>()
    
    private var bag = Set<AnyCancellable>()

    init() {
        input.sink(receiveValue: { [weak self] action in
            guard let self = self else { return }
            
        })
        .store(in: &bag)
    }
}
