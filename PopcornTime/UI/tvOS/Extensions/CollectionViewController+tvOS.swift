

import Foundation

extension CollectionViewController {
    
    private struct AssociatedKeys {
        static var focusIndexPathKey = "CollectionViewController.focusIndexPathKey"
    }
    
    var focusIndexPath: IndexPath {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.focusIndexPathKey) as? IndexPath ?? IndexPath(item: 0, section: 0)
        } set (indexPath) {
            objc_setAssociatedObject(self, &AssociatedKeys.focusIndexPathKey, indexPath, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    override func indexPathForPreferredFocusedView(in collectionView: UICollectionView) -> IndexPath? {
        return focusIndexPath
    }
    
    override var preferredFocusedView: UIView? {
        return collectionView?.cellForItem(at: focusIndexPath)
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        focusIndexPath = indexPath
    }
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let adjustment = scrollView.contentOffset.y + scrollView.contentInset.top
        parent?.navigationItem.leftBarButtonItem?.customView?.frame.origin.y = -adjustment + 44
        parent?.navigationItem.rightBarButtonItems?.forEach({$0.customView?.frame.origin.y = -adjustment + 44})
    }
    
    override func collectionView(_ collectionView: UICollectionView, didUpdateFocusIn context: UICollectionViewFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        if let next = context.nextFocusedIndexPath {
            focusIndexPath = next
        }
        
        if paginated && focusIndexPath.item >= (collectionView.numberOfItems(inSection: focusIndexPath.section) - 10) && !isLoading {
            collectionView.contentInset.bottom += paginationIndicatorInset
            
            let background = UIView(frame: collectionView.bounds)
            let indicator = UIActivityIndicatorView(activityIndicatorStyle: .white)
            
            indicator.translatesAutoresizingMaskIntoConstraints = false
            indicator.startAnimating()
            background.addSubview(indicator)
            
            indicator.centerXAnchor.constraint(equalTo: background.centerXAnchor).isActive = true
            indicator.bottomAnchor.constraint(equalTo: background.bottomAnchor, constant: -55).isActive = true
            collectionView.backgroundView = background
            
            currentPage += 1
            delegate?.load(page: currentPage)
        }
    }
}
