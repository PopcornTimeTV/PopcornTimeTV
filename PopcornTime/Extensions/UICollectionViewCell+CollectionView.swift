

import Foundation

extension UICollectionViewCell {
    
    /// The cell's collection view.
    weak var collectionView: UICollectionView? {
        var superview = self.superview
        
        while superview != nil && !(superview is UICollectionView) {
            superview = superview?.superview
        }
        
        return superview as? UICollectionView
    }
}
