//
//  ResultPreviewCollectionManager.swift
//  AirPrint
//
//  Created by Danyl Timofeyev on 25.11.2021.
//

import Foundation

import Foundation
import UIKit
import Combine

final class StorySelectDisplayManager: NSObject, InteractionFeedbackService { /// NSObject for collection delegate
    enum Action {
        case configure(with: CategorySection)
        case populate(with: [StoryModel])
    }
    
    enum Response {
        case didPressCell(IndexPath)
    }
    
    typealias DataSource = UICollectionViewDiffableDataSource<CategorySection, StoryModel>
    typealias Snapshot = NSDiffableDataSourceSnapshot<CategorySection, StoryModel>
    
    let input = PassthroughSubject<Action, Never>()
    let output = PassthroughSubject<Response, Never>()
        
    private unowned let collectionView: UICollectionView
    private var section: CategorySection!
    private var dataSource: DataSource!
    private var bag = Set<AnyCancellable>()

    init(collectionView: UICollectionView) {
        self.collectionView = collectionView
        super.init()
        handleInput()
    }
    deinit {
        Logger.log(String(describing: self), type: .deinited)
    }
    
    private func configure() {
        collectionView.delegate = self
        collectionView.register(cellClassName: StorySelectionCell.self)
        collectionView.showsVerticalScrollIndicator = false
        dataSource = buildDataSource()
        layoutCollectionAsGrid()
    }
    
    private func handleInput() {
        input.sink(receiveValue: { [weak self] action in
            guard let self = self else { return }
            switch action {
            case .configure(let category):
                self.section = category
                self.configure()
            case .populate(let items):
                self.incrementItems(items)
            }
        })
        .store(in: &bag)
    }
    
    private func incrementItems(_ items: [StoryModel]) {
        var snapshot = dataSource.snapshot()
        if snapshot.numberOfSections == 0 {
            snapshot.appendSections([section])
            snapshot.appendItems(items, toSection: section)
        } else {
            let existingItems = snapshot.itemIdentifiers(inSection: section)
            let items = Set<StoryModel>(items + existingItems).sorted()
            snapshot.appendItems(items, toSection: section)
            snapshot.reloadItems(items)
        }
        Logger.log("collection items count: \(items.count)")
        dataSource?.apply(snapshot, animatingDifferences: false)
    }
   
    private func layoutCollectionAsGrid() {
        let targetHeight = UIScreen.main.bounds.width * 0.25
        let spacing = UIScreen.main.bounds.height * 0.06

        let layout = UICollectionViewCompositionalLayout(sectionProvider: { (sectionIndex, layoutEnvironment) -> NSCollectionLayoutSection? in
            /// item
            let size = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                              heightDimension: .fractionalHeight(1))
            let item = NSCollectionLayoutItem(layoutSize: size)
            item.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
            /// group
            let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(targetHeight))
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitem: item, count: 3)
            group.interItemSpacing = .fixed(spacing)
            group.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: spacing, bottom: 0, trailing: spacing)
            /// section
            let section = NSCollectionLayoutSection(group: group)
            section.interGroupSpacing = spacing
            section.contentInsets = NSDirectionalEdgeInsets(top: spacing, leading: 0, bottom: spacing, trailing: 0)
            return section
        })
        let config = UICollectionViewCompositionalLayoutConfiguration()
        config.scrollDirection = .vertical
        layout.configuration = config
        collectionView.collectionViewLayout = layout
    }
}

private extension StorySelectDisplayManager {
    
    func scrollToItem(withIndexPath indexPath: IndexPath) {
        Logger.log(indexPath.section.description + " " + indexPath.row.description, type: .all)
        collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: false)
    }
    
    func buildDataSource() -> DataSource {
        let dataSource = DataSource(
            collectionView: collectionView,
            cellProvider: { (collectionView, indexPath, model) -> UICollectionViewCell? in
                let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: String(describing: StorySelectionCell.self),
                    for: indexPath) as? StorySelectionCell
                cell?.configure(with: model)
                cell?.output.sink(receiveValue: { event in
                    switch event {
                    case .heartButtonPressed(let cell, let model):
                        model.isFavorite.toggle()
                        cell.heartButton.isSelected = model.isFavorite
                    }
                }).store(in: &self.bag)
                return cell
            })
        return dataSource
    }
}

extension StorySelectDisplayManager: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        output.send(.didPressCell(indexPath))
    }
}
