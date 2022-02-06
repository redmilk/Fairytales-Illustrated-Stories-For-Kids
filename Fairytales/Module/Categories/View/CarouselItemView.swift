//
//  CarouselNode.swift
//  Fairytales
//
//  Created by Danyl Timofeyev on 03.02.2022.
//

import Foundation

final class CarouselItemView: UIView {
    
    @IBOutlet private weak var contentView: UIView!
    @IBOutlet private weak var thumbnail: UIImageView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var primaryButton: BaseButton!
    @IBOutlet private weak var containerBottomConstraint: NSLayoutConstraint!
    @IBOutlet private weak var heartButton: UIButton!
    
    var openButtonCallback: VoidClosure?
    var heartButtonCallback: VoidClosure?
    
    var isFavorite: Bool! {
        didSet {
            guard layoutState != nil else { return }
            heartButton.isSelected = isFavorite
        }
    }
    
    var layoutState: StoryModel.State! {
        didSet {
            guard layoutState != nil else { return }
            switch layoutState! {
            case .idle:
                primaryButton.isHidden = true
                containerBottomConstraint.constant = 40
                titleLabel.font = UIFont.getCustomFont(with: "Lato", of: 16)
            case .selected:
                primaryButton.isHidden = false
                containerBottomConstraint.constant = 15
                titleLabel.font = UIFont.getCustomFont(with: "Lato", of: 20)
                primaryButton.transform = CGAffineTransform.identity.scaledBy(x: 0.1, y: 0.1)
                contentView.layer.removeAllAnimations()
                UIView.animate(withDuration: 0.35, delay: 0, options: [.allowUserInteraction, .curveEaseOut], animations: {
                    self.contentView.layoutIfNeeded()
                    self.primaryButton.transform = .identity
                }, completion: nil)
            }
        }
    }
    
    func configure(with category: CategorySection) {
        heartButton.isHidden = true
        thumbnail.image = category.thumbnail
        titleLabel.text = category.title
    }
    
    func configure(with model: StoryModel) {
        heartButton.isSelected = model.isFavorite
        heartButton.isHidden = model.isHeartHidden
        thumbnail.image = UIImage(named: model.thumbnail)!
        titleLabel.text = model.title
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        customInit()
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        customInit()
    }
    
    @IBAction func didPressHandle(_ sender: Any) {
        openButtonCallback?()
    }
    @IBAction func didPressHeart(_ sender: Any) {
        heartButtonCallback?()
    }
}

// MARK: - Private

private extension CarouselItemView {
    
    func customInit() {
        let bundle = Bundle(for: Self.self)
        bundle.loadNibNamed(String(describing: Self.self), owner: self, options: nil)
        addAndFill(contentView)
    }
}
