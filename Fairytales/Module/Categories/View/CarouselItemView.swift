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
    @IBOutlet weak var heartButton: UIButton!
    @IBOutlet weak var categoryDescriptionLabel: UILabel!
    @IBOutlet weak var stackviewCenterY: NSLayoutConstraint!
    @IBOutlet weak var storyTitleLabel: UILabel!
    @IBOutlet weak var buttonStoryInfo: UIButton!
    @IBOutlet weak var pageCountLabelButton: UIButton!
    
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
                containerBottomConstraint.constant = 40
                contentView.layer.removeAllAnimations()
                UIView.animate(withDuration: 0.35, delay: 0, options: [.allowUserInteraction, .curveEaseOut], animations: {
                    self.primaryButton.isHidden = true
                    self.contentView.layoutIfNeeded()
                }, completion: nil)
            case .selected:
                primaryButton.isHidden = false
                containerBottomConstraint.constant = 15
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
        categoryDescriptionLabel.text = category.description
        storyTitleLabel.isHidden = true
        buttonStoryInfo.isHidden = true
        pageCountLabelButton.isHidden = true
    }
    
    func configure(with model: StoryModel) {
        heartButton.isSelected = model.isFavorite
        categoryDescriptionLabel.isHidden = true
        heartButton.isHidden = model.isHeartHidden
        thumbnail.image = model.imageThumbnail ?? UIImage(named: model.assetThumbnail)
        storyTitleLabel.isHidden = false
        titleLabel.isHidden = true
        storyTitleLabel.text = model.title
        buttonStoryInfo.isHidden = false
        pageCountLabelButton.isHidden = false
        //stackviewCenterY.isActive = true
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
