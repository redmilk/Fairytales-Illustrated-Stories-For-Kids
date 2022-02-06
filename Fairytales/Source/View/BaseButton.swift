//
//  TapAnimatedButton.swift
//  AirPrint
//
//  Created by Danyl Timofeyev on 23.12.2021.
//

import UIKit.UIButton
import UIKit.UIEvent

extension BaseButton {
    @IBInspectable var _identifier: String {
        get { reactiveIdentifier }
        set { reactiveIdentifier = newValue }
    }
}

class BaseButton: UIButton {
    var onTouchesEnded: (() -> Void)?
    var shouldAnimate: Bool = false
    var reactiveIdentifier: String = ""
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        if state == .highlighted {
            isHighlighted = false
        }
        UIView.animate(withDuration: 0.2) {
            self.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        }
    }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        UIView.animate(withDuration: 0.2) {
            self.transform = .identity
        } completion: { [weak self] _ in
            self?.onTouchesEnded?()
        }
        shouldAnimate = false
    }
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        if state == .highlighted {
            isHighlighted = false
        }
    }
    func bounceAnimation(with duration: TimeInterval = 0.7) {
        self.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        UIView.animate(withDuration: duration, delay: 0, usingSpringWithDamping: 0.2, initialSpringVelocity: 6.0, animations: {
            self.transform = .identity
        }, completion: nil)
    }
}

// MARK: - Nib helper

class NibButton: UIButton {
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    func commonInit() {
        addAndFill(loadViewFromNib(nibName: String(describing: Self.self)))
    }
}
