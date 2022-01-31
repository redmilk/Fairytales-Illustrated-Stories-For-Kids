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
        case configure
    }
    
    enum Response {
        case didPressCell
    }
    
    typealias DataSource = UICollectionViewDiffableDataSource<StorySection, StorySectionItem>
    typealias Snapshot = NSDiffableDataSourceSnapshot<StorySection, StorySectionItem>
    
    let input = PassthroughSubject<Action, Never>()
    let output = PassthroughSubject<Response, Never>()
    
    // TODO: - refactor to avoid storing these state fields
    private var isGridLayout: Bool = true
    private var isInSelectionMode: Bool = false
    var currentCenterCellInPagingLayout: StorySectionItem?
    
    private unowned let collectionView: UICollectionView
    private let section = StorySection(items: [], title: "Main Section")
    private var dataSource: DataSource!
    private var timerCancellable: AnyCancellable?
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
        startPostingCenterCell()
    }
    
    private func handleInput() {
        input.sink(receiveValue: { [weak self] action in
            guard let self = self else { return }
            switch action {
            case .configure:
                self.configure()
            }
        })
        .store(in: &bag)
    }
    
    private func incrementItems(_ items: [StorySectionItem]) {
        var snapshot = Snapshot()
        snapshot.appendSections([section])
        snapshot.appendItems(items)
        Logger.log("collection items count: \(items.count)")
        dataSource?.apply(snapshot, animatingDifferences: false)
    }
   
    private func layoutCollectionAsGrid() {
        let aspectRatio = 1.45
        let height = UIScreen.main.bounds.height / 2.5
        let targetHeight = height / aspectRatio
        let width = UIScreen.main.bounds.width
        let targetWidth = width * aspectRatio
        let spacing = UIScreen.main.bounds.width * 0.06
        
        let layout = UICollectionViewCompositionalLayout(sectionProvider: { (sectionIndex, layoutEnvironment) -> NSCollectionLayoutSection? in
            /// item
            let size = NSCollectionLayoutSize(widthDimension: .absolute(targetWidth),
                                              heightDimension: .absolute(targetHeight))
            let item = NSCollectionLayoutItem(layoutSize: size)
            item.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
            /// group
            let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(targetHeight))
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitem: item, count: 2)
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
    
    private func layoutCollectionAsFullSizePages() {
        let layout = UICollectionViewCompositionalLayout(sectionProvider: { (sectionIndex, layoutEnvironment) -> NSCollectionLayoutSection? in
            /// item
            let size = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .fractionalHeight(1))
            let item = NSCollectionLayoutItem(layoutSize: size)
            /// group
            let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(self.collectionView.bounds.height * 0.8))
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitem: item, count: 1)
            group.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20)
            /// section
            let section = NSCollectionLayoutSection(group: group)
            section.interGroupSpacing = 20
            section.contentInsets = NSDirectionalEdgeInsets(top: 20, leading: 0, bottom: 20, trailing: 0)
            section.orthogonalScrollingBehavior = .groupPaging
            return section
        })
        let config = UICollectionViewCompositionalLayoutConfiguration()
        config.scrollDirection = .horizontal
        layout.configuration = config
        collectionView.collectionViewLayout = layout
    }
    
    private func startPostingCenterCell() {
        timerCancellable?.cancel()
        timerCancellable = Timer.publish(every: 0.5, on: .main, in: .common)
            .autoconnect()
            .compactMap { [weak self] _ in self?.getCenterScreenCollectionItem() }
            .removeDuplicates()
            .sink(receiveValue: { [weak self] dataBox in
                print(dataBox.id)
                self?.currentCenterCellInPagingLayout = dataBox
            })
    }
    
    private func getCenterScreenCollectionItem() -> StorySectionItem? {
        let centerPoint = CGPoint(x: collectionView.bounds.midX, y: collectionView.bounds.midY)
        guard !isGridLayout,
              collectionView.numberOfItems(inSection: 0) > 0,
              let indexPath = collectionView.indexPathForItem(at: centerPoint),
              let cell = collectionView.cellForItem(at: indexPath) as? StorySelectionCell else { return nil }
        return nil
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
            cellProvider: { (collectionView, indexPath, dataBox) -> UICollectionViewCell? in
                let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: String(describing: StorySelectionCell.self),
                    for: indexPath) as? StorySelectionCell
                //cell?.configure(withDataBox: dataBox, isInSelectionMode: self.isInSelectionMode)
                //cell?.dropShadow(color: .darkGray, opacity: 1.0, offSet: CGSize(width: -2, height: 2), radius: 5, scale: true)
                return cell
            })
        return dataSource
    }
}

extension StorySelectDisplayManager: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
//        guard let cell = collectionView.cellForItem(at: indexPath) as? StorySelectionCell,
//              let story = cell.story else { return }
//        output.send(.didPressCell)
    }
}
