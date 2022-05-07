//
//  ParentalGate.swift
//  Fairytales
//
//  Created by Danyl Timofeyev on 06.05.2022.
//

import Foundation
import Combine

final class ParentalGate {
    
    var currentCorrectAnswer: Int!
    var bag = Set<AnyCancellable>()
    
    func generateTaskContent() -> AnyPublisher<(String, [Int]), Never> {
        [Int.random(in: 11...99), Int.random(in:  11...99), Int.random(in:  11...99), Int.random(in:  11...99), Int.random(in:  11...99), Int.random(in:  11...99), Int.random(in:  11...99), Int.random(in:  11...99), Int.random(in:  11...99), Int.random(in:  11...99), Int.random(in:  11...99), Int.random(in:  11...99), Int.random(in:  11...99), Int.random(in:  11...99), Int.random(in:  11...99), Int.random(in:  11...99), Int.random(in:  11...99), Int.random(in:  11...99), Int.random(in:  11...99), Int.random(in:  11...99), Int.random(in:  11...99), Int.random(in: 11...99), Int.random(in:  11...99), Int.random(in:  11...99)
        ].publisher
            .collect()
            .flatMap({ (arr: [Int]) -> AnyPublisher<Int, Never> in
            Publishers.Sequence(sequence: arr).eraseToAnyPublisher()
            }).removeAllDuplicates()
            .collect(5)
            .prefix(1)
            .map({ [weak self] arr -> (String, [Int]) in
                var answers = arr
                if answers.count == 4 {
                    answers.append(Int.random(in:  11...99))
                }
                let first = Int.random(in:  11...49)
                let second = Int.random(in:  11...49)
                self?.currentCorrectAnswer = first + second
                let taskText = "\(first) + \(second) ="
                answers[0] = first + second
                return (taskText, answers.shuffled())
            })
            .eraseToAnyPublisher()
    }
    
    func displayParentalGate(onSuccess: @escaping VoidClosure, onFail: @escaping VoidClosure) {
        let first = Int.random(in: 11...99)
        let second = Int.random(in: 11...99)

        let alert = UIAlertController(title: "Родительский конртоль",
                                      message: "Для того чтобы продолжить решите задачу:\n\(first) + \(second) = ?",
                                      preferredStyle: .alert)

        alert.addTextField { (textField) in
            textField.keyboardType = .numberPad
            //textField.text = "Some default text"
        }

        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak alert] _ in
            guard let alert = alert, let result = Int(alert.textFields![0].text ?? "") else { return }
            result == first + second ? onSuccess() : onFail()
        }))
        
        alert.addAction(UIAlertAction(title: "Отменить", style: .cancel, handler: { _ in }))
        
        UIViewController.topViewController?.present(alert, animated: true, completion: nil)
    }
    
}
