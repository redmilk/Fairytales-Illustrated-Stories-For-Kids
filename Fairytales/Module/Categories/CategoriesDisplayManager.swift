//
//  CategoriesDisplayManager.swift
//  Fairytales
//
//  Created by Danyl Timofeyev on 07.04.2022.
//

import Foundation
import UIKit
import Combine

final class CategoriesDisplayManager: NSObject, InteractionFeedbackService { /// NSObject for collection delegate
    enum Action {
        case didSelectMaskWithMaskManagerIndex(_ index: Int)
        case willDisplayCell(IndexPath)
    }
    
    typealias DataSource = UICollectionViewDiffableDataSource<CategorySection, StoryModel>
    typealias Snapshot = NSDiffableDataSourceSnapshot<CategorySection, StoryModel>
    
    let output = PassthroughSubject<CategoriesDisplayManager.Action, Never>()
    var coordinator: CoordinatorPreservable?
    private unowned let collectionView = UICollectionView()
    private var dataSource: DataSource!
    private var isFirstCellWasAlreadyDisplayed = false
   
    deinit {
        Logger.log(String(describing: self), type: .deinited)
    }
    
    func configure(withCoordinator coordinator: CoordinatorPreservable?) {
        self.coordinator = coordinator
        collectionView.delegate = self
        collectionView.isPagingEnabled = true
        collectionView.alwaysBounceVertical = false
        collectionView.showsHorizontalScrollIndicator = false
        dataSource = buildDataSource()
        layoutCollection()
    }
    
    func update(withSections sections: [CategorySection], withIndexPath indexPath: IndexPath) {
        applySnapshot(sections: sections, withIndexPath: indexPath)
    }
}

// MARK: - Internal

private extension CategoriesDisplayManager {
    func applySnapshot(sections: [CategorySection], withIndexPath indexPath: IndexPath) {
        var newSnapshot = Snapshot()
        newSnapshot.appendSections(sections)
        sections.forEach { newSnapshot.appendItems($0.items, toSection: $0) }
        dataSource?.apply(newSnapshot, animatingDifferences: false)
        collectionView.isPagingEnabled = false
        scrollToItem(withIndexPath: indexPath)
        collectionView.isPagingEnabled = true
    }
    
    func scrollToItem(withIndexPath indexPath: IndexPath) {
        Logger.log(indexPath.section.description + " " + indexPath.row.description, type: .all)
        collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: false)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: { [weak self] in
            self?.isFirstCellWasAlreadyDisplayed = true
        })
    }
    
    func buildDataSource() -> DataSource {
        let dataSource = DataSource(
            collectionView: collectionView,
            cellProvider: { (collectionView, indexPath, item) -> UICollectionViewCell? in
                let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: String(describing: StorySelectionCell.self),
                    for: indexPath) as? StorySelectionCell
                var sub: AnyCancellable?
                return cell
            })
        return dataSource
    }
    
    func layoutCollection() {
        let layout = UICollectionViewCompositionalLayout(sectionProvider: { (_, _) -> NSCollectionLayoutSection? in
            /// item
            let size = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .fractionalHeight(1))
            let item = NSCollectionLayoutItem(layoutSize: size)
            /// group
            let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .fractionalHeight(1))
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitem: item, count: 1)
            /// section
            let section = NSCollectionLayoutSection(group: group)
            return section
        })
        let config = UICollectionViewCompositionalLayoutConfiguration()
        config.scrollDirection = .vertical
        layout.configuration = config
        collectionView.collectionViewLayout = layout
    }
}

extension CategoriesDisplayManager: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    }
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        output.send(.willDisplayCell(indexPath))
        guard isFirstCellWasAlreadyDisplayed else { return }
        generateInteractionFeedback()
    }
    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        (cell as? StorySelectionCell)?.bag.removeAll()
    }
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let numberOfCells = self.collectionView.numberOfItems(inSection: 0)
        let cellHeight = self.collectionView.visibleCells.first!.bounds.height
        
        if numberOfCells == 1 {
            return
        }
        let regularContentOffset = cellHeight * CGFloat(numberOfCells - 2)
        if scrollView.contentOffset.y >= cellHeight * CGFloat(numberOfCells - 1) {
            scrollView.contentOffset = CGPoint(x: 0.0, y: scrollView.contentOffset.y - regularContentOffset)
        } else if scrollView.contentOffset.y < cellHeight {
            scrollView.contentOffset = CGPoint(x: 0.0, y: scrollView.contentOffset.y + regularContentOffset)
        }
    }
}
