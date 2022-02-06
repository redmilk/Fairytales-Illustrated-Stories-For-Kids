//
//  
//  LaunchAnimationViewController.swift
//  Fairytales
//
//  Created by Danyl Timofeyev on 06.02.2022.
//
//

import UIKit
import Combine


// MARK: - LaunchAnimationViewController

final class LaunchAnimationViewController: BaseViewController {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var animatableView: UIView!
    let emitter = CartoonStarsEmitter()
    
    init(coordinator: Coordinatable) {
        super.init(coordinator: coordinator, type: Self.self, initialState: BaseState())
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    deinit {
        Logger.log(String(describing: self), type: .deinited)
    }
    override func applyStyling() {
        view.insertSubview(emitter, at: 1)
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        animatableView.clipsToBounds = true
        view.subviews.first?.bringSubviewToFront(imageView)
        emitter.center = view.center
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        animatableView.layer.cornerRadius = animatableView.bounds.height / 2

        let finalTransform = CGAffineTransform.identity.scaledBy(x: 10, y: 10)
        UIView.animate(withDuration: 1, delay: 0.0, options: [], animations: {
            self.animatableView.transform = finalTransform
            self.emitter.frame = self.animatableView.frame
            self.emitter.center = self.animatableView.center
        }, completion: { [weak self] _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                (self?.coordinator as? LaunchAnimationCoordinator)?.startAppFlow()
            }
        })
    }
}
