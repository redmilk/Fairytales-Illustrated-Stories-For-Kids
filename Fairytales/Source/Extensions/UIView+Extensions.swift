//
//  UIView+Extensions.swift
//  ReactiveMovies
//
//  Created by Danyl Timofeyev on 17.05.2021.
//

import UIKit.UIView
import QuartzCore
import Combine

protocol XibDesignable: AnyObject { }
extension UIView: XibDesignable { }
extension XibDesignable where Self: UIView {
    static func instantiateFromXib() -> Self {
        let dynamicMetatype = Self.self
        let bundle = Bundle(for: dynamicMetatype)
        let nib = UINib(nibName: "\(dynamicMetatype)", bundle: bundle)
        guard let view = nib.instantiate(withOwner: nil, options: nil).first as? Self else {
            fatalError("Could not load view from nib file.")
        }
        return view
    }
}

// MARK: - Init from Nib
extension UIView {
    func loadViewFromNib(nibName: String) -> UIView {
        if nibExists(name: nibName) {
            return getNibForClass(named: nibName)
        } else if let superClass = superclass.self {
            let parentName = String(describing: superClass)
            if nibExists(name: parentName) {
                return getNibForClass(named: parentName)
            }
        }
        fatalError("\"\(nibName).xib\" does not exist")
    }
    
    func nibExists(name: String) -> Bool {
        !(Bundle.main.path(forResource: name, ofType: "nib") == nil)
    }
    
    func getNibForClass(named nibName: String) -> UIView {
        let bundle = Bundle(for: Self.self)
        let nib = UINib(nibName: nibName, bundle: bundle)
        let view = nib.instantiate(withOwner: self, options: nil)[0] as! UIView
        return view
    }
}

// MARK: - Constraints
extension UIView {
    func constraintToSides(inside superView: UIView) {
        translatesAutoresizingMaskIntoConstraints = false
        leadingAnchor.constraint(equalTo: superView.leadingAnchor).isActive = true
        trailingAnchor.constraint(equalTo: superView.trailingAnchor).isActive = true
        topAnchor.constraint(equalTo: superView.topAnchor).isActive = true
        bottomAnchor.constraint(equalTo: superView.bottomAnchor).isActive = true
    }
    
    func addAndFill(_ subview: UIView) {
        subview.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(subview)
        self.addConstraints([
            NSLayoutConstraint(item: subview, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: subview, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: subview, attribute: .left, relatedBy: .equal, toItem: self, attribute: .left, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: subview, attribute: .right, relatedBy: .equal, toItem: self, attribute: .right, multiplier: 1, constant: 0)
        ])
    }
}

// MARK: - Styling
extension UIView: InteractionFeedbackService {
    func addCornerRadius(_ radius: CGFloat) {
        self.clipsToBounds = true
        self.layer.cornerRadius = radius
    }
    func addBorder(_ width: CGFloat, _ color: UIColor) {
        self.clipsToBounds = true
        self.layer.borderWidth = width
        self.layer.borderColor = color.cgColor
    }
    func animateFadeInOut(_ duration: CGFloat, isFadeIn: Bool, completion: (() -> Void)?) {
        self.alpha = isFadeIn ? 0 : 1
        UIView.animate(withDuration: 0.3, delay: 0.0, options: [.curveEaseInOut], animations: {
            self.alpha = isFadeIn ? 1 : 0
        }, completion: { _ in
            completion?()
        })
    }
    func addGradientBorder(to view: UIView, radius: CGFloat, width: CGFloat, colors: [UIColor]) {
        let gradient = CAGradientLayer()
        gradient.frame = CGRect(origin: CGPoint.zero, size: view.frame.size)
        gradient.colors = colors.map { $0.cgColor }
        let shape = CAShapeLayer()
        shape.lineWidth = width
        shape.path = UIBezierPath(roundedRect: view.bounds, cornerRadius: radius).cgPath
        shape.strokeColor = UIColor.black.cgColor
        shape.fillColor = UIColor.clear.cgColor
        gradient.mask = shape
        view.layer.addSublayer(gradient)
    }
    func dropShadow(scale: Bool = true) {
        layer.masksToBounds = false
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.5
        layer.shadowOffset = CGSize(width: -1, height: 1)
        layer.shadowRadius = 1
        layer.shadowPath = UIBezierPath(rect: bounds).cgPath
        layer.shouldRasterize = true
        layer.rasterizationScale = scale ? UIScreen.main.scale : 1
    }
    func dropShadow(color: UIColor, opacity: Float = 0.5,
                    offSet: CGSize, radius: CGFloat = 1, scale: Bool = true) {
        layer.masksToBounds = false
        layer.shadowColor = color.cgColor
        layer.shadowOpacity = opacity
        layer.shadowOffset = offSet
        layer.shadowRadius = radius
        layer.shadowPath = UIBezierPath(rect: self.bounds).cgPath
        layer.shouldRasterize = true
        layer.rasterizationScale = scale ? UIScreen.main.scale : 1
    }
    
    // MARK: - Animations
    func animateShake(duration: TimeInterval = 0.6, delay: TimeInterval = 5) {
        let animation = CAKeyframeAnimation(keyPath: "transform.translation.x")
        animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.linear)
        animation.duration = duration
        animation.values = [-20.0, 20.0, -20.0, 20.0, -10.0, 10.0, -5.0, 5.0, 0.0 ]
        animation.beginTime = CACurrentMediaTime() + delay
        layer.add(animation, forKey: "shake")
    }
    func animateBounceAndShadow() -> AnyCancellable? {
        var cancelable: AnyCancellable?
        cancelable = Timer.publish(every: 2, tolerance: .none, on: RunLoop.main, in: .common, options: nil)
            .autoconnect()
            .eraseToAnyPublisher()
            .sink(receiveValue: { [weak self] _ in
                self?.transform = CGAffineTransform.init(scaleX: 0.9, y: 0.9)
                UIView.animate(withDuration: 1.5, delay: 0.0, usingSpringWithDamping: 0.5, initialSpringVelocity: 15, options: [.curveEaseInOut, .allowUserInteraction], animations: {
                    self?.transform = .identity
                }, completion: nil)
                //self?.generateInteractionFeedback()
                let animation = CABasicAnimation(keyPath: "shadowOpacity")
                animation.fromValue = 1.0
                animation.toValue = 0.0
                animation.duration = 0.3
                self?.layer.add(animation, forKey: animation.keyPath)
            })
        return cancelable
    }
    func animateShadowGlow() {
        let animation = CABasicAnimation(keyPath: "shadowRadius")
        animation.fromValue = 0.0
        animation.toValue = 30.0
        animation.duration = 0.5
        animation.autoreverses = true
        animation.repeatCount = .infinity
        self.layer.add(animation, forKey: animation.keyPath)
    }
    func animateFadeIn(_ duration: TimeInterval, delay: TimeInterval = 0, finalAlpha: CGFloat = 1.0) {
        self.alpha = 0
        UIView.animate(withDuration: duration, delay: delay, options: [.allowUserInteraction]) {
            self.alpha = finalAlpha
        }
    }
    func animateFallingWithDeformation(duration: TimeInterval, delay: TimeInterval) {
        UIView.animateKeyframes(withDuration: duration, delay: delay, options: [.calculationModeCubic], animations: {
            UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 0.0, animations: {
                self.transform = CGAffineTransform.identity.translatedBy(x: 0, y: -300)
            })
            UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 0.5, animations: {
                self.transform = .identity
            })
            UIView.addKeyframe(withRelativeStartTime: 0.2, relativeDuration: 0.2, animations: {
                self.transform = CGAffineTransform.identity.scaledBy(x: 1.0, y: 0.4)
            })
            UIView.addKeyframe(withRelativeStartTime: 0.6, relativeDuration: 0.2, animations: {
                self.transform = .identity
            })
        }, completion: nil)
    }
    func animateRotationAround(_ spinsNumber: Float, duration: TimeInterval) {
        let spinAnimation = CABasicAnimation.init(keyPath: "transform.rotation")
        spinAnimation.toValue = NSNumber(value: spinsNumber * -Float.pi)
        spinAnimation.duration = duration
        layer.add(spinAnimation, forKey: "spinAnimation")
    }
}

class ShimmerView: UIView {
    func startShimmering() {
        let light = UIColor.white.cgColor
        let alpha = UIColor.white.withAlphaComponent(0.0).cgColor

        let gradient = CAGradientLayer()
        gradient.colors = [alpha, light, alpha]
        gradient.frame = CGRect(x: -self.bounds.size.width, y: 0, width: 3 * self.bounds.size.width, height: self.bounds.size.height)
        gradient.startPoint = CGPoint(x: 1.0, y: 0.525)
        gradient.endPoint = CGPoint(x: 0.0, y: 0.5)
        gradient.locations = [0.1, 0.5, 0.9]
        self.layer.mask = gradient

        let shimmer = CABasicAnimation(keyPath: "locations")
        shimmer.fromValue = [0.0, 0.1, 0.2]
        shimmer.toValue = [0.8, 0.9, 1.0]
        shimmer.duration = 1.5
        shimmer.fillMode = .forwards
        shimmer.isRemovedOnCompletion = false

        let group = CAAnimationGroup()
        group.animations = [shimmer]
        group.duration = 2
        group.repeatCount = HUGE
        gradient.add(group, forKey: "shimmer")
    }
}

extension UIView {
    
    @IBInspectable var _cornerRadius: CGFloat {
        get {
            return layer.cornerRadius
        }
        set {
            layer.cornerRadius = newValue
            layer.masksToBounds = newValue > 0
        }
    }
    
    @IBInspectable var _borderWidth: CGFloat {
        get {
            return layer.borderWidth
        }
        set {
            layer.borderWidth = newValue
        }
    }
    
    @IBInspectable var _borderColor: UIColor? {
        get {
            return UIColor(cgColor: layer.borderColor!)
        }
        set {
            layer.borderColor = newValue?.cgColor
        }
    }
}

//let view = ShimmerView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
//PlaygroundPage.current.liveView = view
//
//view.backgroundColor = .blue
//view.startShimmering()
