//
//  CardLayout.swift
//  EasemobScenariosDemo
//
//  Created by 朱继超 on 2024/8/8.
//

import UIKit

final class StackCardLayout: UICollectionViewLayout {
    
    // 限制最多显示的卡片数量为3
    private let maxVisibleCount: Int = 3
    
    override func prepare() {
        super.prepare()
        collectionView?.isPagingEnabled = false
        collectionView?.showsVerticalScrollIndicator = false
        collectionView?.showsHorizontalScrollIndicator = false
        collectionView?.decelerationRate = .fast
    }
    
    override var collectionViewContentSize: CGSize {
        return CGSize(width: collectionView?.frame.width ?? 0,
                      height: collectionView?.frame.height ?? 0)
    }
    
    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return true
    }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        guard let collectionView = collectionView else { return nil }
        
        let totalItemsCount = collectionView.numberOfItems(inSection: 0)
        let startIndex = max(0, totalItemsCount - maxVisibleCount)
        var endIndex = totalItemsCount - 1
        if endIndex < startIndex {
            endIndex = startIndex
        }
        var attributes: [UICollectionViewLayoutAttributes] = []
        for i in startIndex...endIndex {
            if let cellAttributes = layoutAttributesForItem(at: IndexPath(item: i, section: 0)) {
                attributes.append(cellAttributes)
            }
        }
        
        return attributes
    }
    
    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        guard let collectionView = collectionView else { return nil }
        
        let totalItemsCount = collectionView.numberOfItems(inSection: 0)
        let lastIndex = totalItemsCount - 1
        let currentItemIndex = indexPath.item
        
        let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
        
        // 每个cell的尺寸，根据collectionView的尺寸，留出一定间距
        let width = collectionView.bounds.width - 16
        let height = collectionView.bounds.height - 16
        
        let frame = CGRect(x: 8, y: 16, width: width, height: height)
        attributes.frame = frame
        
        // 计算cell的位置
        let indexOffset = lastIndex - currentItemIndex
        let scaleFactor: CGFloat = 0.05
        
        // 根据堆叠顺序来调整zIndex、位置和缩放
        attributes.zIndex = maxVisibleCount - indexOffset
        let offset = CGFloat(indexOffset) * 8
        attributes.transform = CGAffineTransform(translationX: 0, y: -offset).scaledBy(x: 1 - (scaleFactor * CGFloat(indexOffset)), y: 1 - (scaleFactor * CGFloat(indexOffset)))
        
        return attributes
    }
}
