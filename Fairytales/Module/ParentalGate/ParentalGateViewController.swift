//
//  
//  ParentalGateViewController.swift
//  Fairytales
//
//  Created by Danyl Timofeyev on 06.05.2022.
//
//

import UIKit
import Combine

// MARK: - ParentalGate State and Buttons
extension ParentalGateViewController {
    class State: BaseState {
        override init() { }
        var correctAnswer: String!
        var taskContent: (String, [Int])!
    }
    enum Buttons {
        case back, first, second, third, fourth, fifth
    }
}

// MARK: - ParentalGateViewController
final class ParentalGateViewController: BaseViewController {
    
    @IBOutlet weak var backButton: BaseButton!
    
    @IBOutlet weak var firstButton: BaseButton!
    @IBOutlet weak var secondButton: BaseButton!
    @IBOutlet weak var thirdButton: BaseButton!
    @IBOutlet weak var fourthButton: BaseButton!
    @IBOutlet weak var fifthButton: BaseButton!
    
    @IBOutlet weak var taskLabel: UILabel!
    @IBOutlet weak var taskAnswerLabel: UILabel!
    private let emitter = ParticleEmitterView()
    
    private var stateValue: State { state.value as! State }
    
    init(coordinator: ParentalGateCoordinator) {
        let initialState = State()
        super.init(coordinator: coordinator, type: Self.self, initialState: initialState)
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    deinit {
        Logger.log(String(describing: self), type: .deinited)
    }
    
    override func configure() {
        let parentalGate = ParentalGate()
        parentalGate.generateTaskContent().sink(receiveValue: { [weak self] taskContent in
            guard let self = self else { return }
            self.stateValue.taskContent = taskContent
            self.stateValue.correctAnswer = parentalGate.currentCorrectAnswer.description
            for (index, button) in [self.firstButton, self.secondButton, self.thirdButton, self.fourthButton, self.fifthButton].enumerated() {
                button?.setTitle(self.stateValue.taskContent.1[index].description, for: .normal)
            }
            self.taskLabel.text = self.stateValue.taskContent.0
        }).store(in: &bag)
    }
    override func applyStyling() {
        taskAnswerLabel.addCornerRadius(6)
        taskAnswerLabel.addBorder(2, .lightGray)
        emitter.tag = 1
        emitter.alpha = 1
        emitter.isUserInteractionEnabled = false
        view.insertSubview(emitter, at: 1)
        emitter.constraintToSides(inside: view)
    }
    
    override func handleState() {
        state.compactMap { $0 as? ParentalGateViewController.State }
            .sink(receiveValue: { [weak self] state in
                guard let self = self else { return }
                
            }).store(in: &bag)
    }
    
    override func handleEvents() {
        // lifecycle
        lifecycle.sink(receiveValue: { [weak self] lifecycle in
            guard let self = self else { return }
            switch lifecycle {
            case .viewDidLoad: break
            case .viewDidAppear: break
            case _: break
            }
        }).store(in: &bag)
        // buttons
        Publishers.MergeMany(
            backButton.publisher().map { _ in Buttons.back },
            firstButton.publisher().map { _ in Buttons.first },
            secondButton.publisher().map { _ in Buttons.second },
            thirdButton.publisher().map { _ in Buttons.third },
            fourthButton.publisher().map { _ in Buttons.fourth },
            fifthButton.publisher().map { _ in Buttons.fifth }
        ).sink(receiveValue: { [weak self] button in
                guard let self = self else { return }
                switch button {
                case .back: self.coordinator.end()
                case .first: self.answer(with: self.firstButton.titleLabel!.text!)
                case .second: self.answer(with: self.secondButton.titleLabel!.text!)
                case .third: self.answer(with: self.thirdButton.titleLabel!.text!)
                case .fourth: self.answer(with: self.fourthButton.titleLabel!.text!)
                case .fifth: self.answer(with: self.fifthButton.titleLabel!.text!)
                }
            }).store(in: &bag)
    }
}

// MARK: - Internal
private extension ParentalGateViewController {
    
    func answer(with answer: String) {
        guard answer == stateValue.correctAnswer else {
            return onWrongAnswer()
        }
        onCorrectAnswer()
    }
    
    func onCorrectAnswer() {
        taskAnswerLabel.text = stateValue.correctAnswer
        
        let colourAnim = CABasicAnimation(keyPath: "backgroundColor")
        colourAnim.fromValue = #colorLiteral(red: 0.5563425422, green: 0.9793455005, blue: 0, alpha: 1).cgColor
        colourAnim.toValue = UIColor.white.cgColor
        colourAnim.duration = 0.1
        //taskAnswerLabel.layer.add(colourAnim, forKey: "colourAnimation")
        let scale = CABasicAnimation(keyPath: "transform.scale")
        scale.fromValue = 1.5
        scale.toValue = 1
        scale.duration = 0.3
        taskAnswerLabel.layer.add(scale, forKey: "scale")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4, execute: { [weak self] in
            (self?.coordinator as? ParentalGateCoordinator)?.endWithAnswer(true)
        })
    }
    
    func onWrongAnswer() {
        //taskAnswerLabel.text = stateValue.correctAnswer
        let animation = CAKeyframeAnimation(keyPath: "transform.translation.x")
        animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.linear)
        animation.duration = 0.5
        animation.values = [-10.0, 10.0, -10.0, 10.0, -5.0, 5.0, -2.5, 2.5, 0.0 ]
        animation.beginTime = CACurrentMediaTime()
        self.view.layer.add(animation, forKey: "shake")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: { [weak self] in
            (self?.coordinator as? ParentalGateCoordinator)?.endWithAnswer(false)
        })
    }
}
