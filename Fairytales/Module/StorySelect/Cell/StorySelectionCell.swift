//
//  StorySelectionCell.swift
//  Fairytales
//
//  Created by Danyl Timofeyev on 31.01.2022.
//

import UIKit
import Combine

final class StorySelectionCell: UICollectionViewCell {
    
    enum Event {
        case heartButtonPressed(cell: StorySelectionCell, model: StoryModel)
    }
    
    @IBOutlet weak var thumbnail: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var heartButton: UIButton!
    
    override func awakeFromNib() {
        heartButton.publisher().sink(receiveValue: { [weak self] _ in
            guard let self = self, let model = self.model else { return }
            self.output.send(.heartButtonPressed(cell: self, model: model))
        }).store(in: &bag)
    }
    
    override func prepareForReuse() {
        bag.removeAll()
        output = PassthroughSubject<Event, Never>()
        model = nil
    }

    var output = PassthroughSubject<Event, Never>()
    var bag = Set<AnyCancellable>()
    var model: StoryModel?

    func configure(with model: StoryModel) {
        self.model = model
        thumbnail.image = model.imageThumbnail ?? UIImage(named: model.assetThumbnail)
        titleLabel.text = model.title
        heartButton.isSelected = model.isFavorite
    }
}
