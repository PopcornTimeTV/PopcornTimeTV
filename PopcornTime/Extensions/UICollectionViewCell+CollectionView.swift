

import Foundation

extension UICollectionViewCell {
    
    /// The cell's collection view.
    weak var collectionView: UICollectionView! {
        var superview = self.superview
        
        while !(superview is UICollectionView) {
            superview = superview?.superview
        }
        
        if let collectionView = superview as? UICollectionView {
            return collectionView
        }
        
        fatalError("Unexpected view hierarchy; UICollectionView not found.")
    }
}
