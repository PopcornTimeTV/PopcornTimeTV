

import Foundation

extension UICollectionViewController {
    
    func collectionViewWillReloadData(_ collectionView: UICollectionView) { }
    func collectionViewDidReloadData(_ collectionView: UICollectionView) { }
    
}

extension UICollectionView {
    
    @objc private func pctReloadData() {
        if let parent = parent as? UICollectionViewController {
            parent.collectionViewWillReloadData(self)
            self.pctReloadData()
            parent.collectionViewDidReloadData(self)
        } else {
            self.pctReloadData()
        }
    }
    
    open override class func initialize() {
        
        if self !== UICollectionView.self {
            return
        }
        
        DispatchQueue.once() {
            let originalMethod = class_getInstanceMethod(self, #selector(reloadData))
            let swizzledMethod = class_getInstanceMethod(self, #selector(pctReloadData))
            method_exchangeImplementations(originalMethod, swizzledMethod)
        }
    }
}
