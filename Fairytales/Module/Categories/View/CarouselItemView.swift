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
    @IBOutlet weak var primaryButton: BaseButton!
    @IBOutlet private weak var containerBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var heartButton: UIButton!
    @IBOutlet weak var categoryDescriptionLabel: UILabel!
    @IBOutlet weak var stackviewCenterY: NSLayoutConstraint!
    @IBOutlet weak var storyTitleLabel: UILabel!
    @IBOutlet weak var buttonStoryInfo: UIButton!
    @IBOutlet weak var pageCountLabelButton: UIButton!
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var activitySpinnerContainer: UIView!
    
    var openButtonCallback: VoidClosure?
    var heartButtonCallback: VoidClosure?
    
    var isLoading: Bool = false
    
    var isFavorite: Bool! {
        didSet {
            guard isFavorite != nil else { return }
            heartButton.isSelected = isFavorite
        }
    }
    
    var isPersisted: Bool! {
        didSet {
            guard isPersisted != nil else { return }
            primaryButton.setTitle(isPersisted ? "Открыть" : "Загрузить", for: .normal)
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
                    self.activitySpinnerContainer.isHidden = true
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
                    self.activitySpinnerContainer.isHidden = !self.isLoading
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
        progressView.isHidden = true
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
        pageCountLabelButton.setTitle("\(model.pages.count) стр", for: .normal)
        progressView.isHidden = true
        //stackviewCenterY.isActive = true
        let indicator = CirclesActivityIndicator().makeActivityIndicator(height: activitySpinnerContainer.bounds.height - 14, color: .white)
        activitySpinnerContainer.addAndFill(indicator, padding: UIEdgeInsets(top: 4, left: 4, bottom: 4, right: 0))
        activitySpinnerContainer.isHidden = true
    }
    
    func startAnimateDownloading() {
        progressView.isHidden = false
        activitySpinnerContainer.isHidden = false
        primaryButton.setTitle("", for: .normal)
    }
    
    func stopAnimateDownloading() {
        progressView.isHidden = true
        primaryButton.setTitle("Открыть", for: .normal)
        activitySpinnerContainer.isHidden = true
    }
    
    func updateProgress(_ value: CGFloat) {
        progressView.isHidden = false
        progressView.progress = Float(value)
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
