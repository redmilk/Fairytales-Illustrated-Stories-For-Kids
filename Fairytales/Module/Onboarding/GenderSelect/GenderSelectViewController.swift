//
//  
//  GenderSelectViewController.swift
//  Fairytales
//
//  Created by Danyl Timofeyev on 21.02.2022.
//
//

import UIKit
import Combine

enum KidActor: Codable {
    case boy
    case girl
}

extension GenderSelectViewController {
    class State: BaseState {
        override init() { }

        var currentKid: KidActor = .boy
        var name: String = ""
    }
}

// MARK: - GenderSelectViewController
final class GenderSelectViewController: BaseViewController, UserSessionServiceProvidable {
    enum Button {
        case boy
        case girl
        case back
        case continueButton
    }
    
    @IBOutlet weak var nameTextfield: UITextField!
    @IBOutlet weak var boyButton: BaseButton!
    @IBOutlet weak var girlButton: BaseButton!
    @IBOutlet weak var backButton: BaseButton!
    @IBOutlet weak var continueButton: BaseButton!

    var stateValue: GenderSelectViewController.State { state.value as! GenderSelectViewController.State }
    private let isFromSettings: Bool
    
    init(coordinator: GenderSelectCoordinator, isFromSettings: Bool = false) {
        self.isFromSettings = isFromSettings
        super.init(coordinator: coordinator, type: Self.self, initialState: State())
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func configure() {
        nameTextfield.delegate = self
        continueButton.isEnabled = false
        nameTextfield.text = userSession.kidName
        if isFromSettings {
            continueButton.setTitle("Изменить", for: .normal)
            continueButton.isEnabled = true
        }
    }
    
    override func handleEvents() {
        Publishers.Merge4(boyButton.publisher().map { _ in return Button.boy },
                          girlButton.publisher().map { _ in return Button.girl },
                          continueButton.publisher().map { _ in return Button.continueButton },
                          backButton.publisher().map { _ in return Button.back })
            .sink(receiveValue: { [weak self] kidActor in
                guard let state = self?.stateValue else { return }
            switch kidActor {
            case .girl:
                self?.boyButton.isSelected = false
                self?.girlButton.isSelected = true
                self?.stateValue.currentKid = .girl
            case .boy:
                self?.boyButton.isSelected = true
                self?.girlButton.isSelected = false
                self?.stateValue.currentKid = .boy
            case .continueButton:
                state.name = self?.nameTextfield.text ?? ""
                let isKidBoy = self?.boyButton.isSelected ?? true
                state.currentKid = isKidBoy ? KidActor.boy : KidActor.girl
                guard let self = self, state.name.count > 1 else { return }
                self.userSession.kidName = state.name
                self.userSession.kidActor = state.currentKid
                if !self.isFromSettings {
                    OnboardingManager.shared?.onboardingFinishAction()
                    OnboardingManager.shared = nil
                } else {
                    self.coordinator.end()
                }
            case .back:
                self?.coordinator.end()
            }
        }).store(in: &bag)
        
        lifecycle.sink(receiveValue: { [weak self] lifecycle in
            switch lifecycle {
            case .viewWillAppear: self?.navigationController?.setNavigationBarHidden(true, animated: false)
            case .viewDidDisappear: self?.navigationController?.setNavigationBarHidden(false, animated: false)
            case _: break
            }
        }).store(in: &bag)
    }
    override func handleState() {
        state.compactMap { $0 as? GenderSelectViewController.State }
        .sink(receiveValue: { [weak self] state in
            guard let self = self else { return }
            
        }).store(in: &bag)
    }
    
    @IBAction func textDidChange(_ sender: UITextField) {
        sender.text = sender.text?.capitalized
        if (sender.text?.count ?? 0) > 2 {
            stateValue.name = (sender.text ?? "").capitalized
            continueButton.isEnabled = true
        } else {
            continueButton.isEnabled = false
        }
    }
}

extension GenderSelectViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}


