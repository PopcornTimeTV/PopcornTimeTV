

import Foundation

extension CollectionViewController {
    
    private struct AssociatedKeys {
        static var refreshControlKey = "CollectionViewController.refreshControlKey"
        static var isRefreshableKey  = "CollectionViewController.isRefreshableKey"
    }
    
    var refreshControl: UIRefreshControl? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.refreshControlKey) as? UIRefreshControl
        } set {
            objc_setAssociatedObject(self, &AssociatedKeys.refreshControlKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    var isRefreshable: Bool  {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.isRefreshableKey) as? Bool ?? false
        } set (refreshable) {
            objc_setAssociatedObject(self, &AssociatedKeys.isRefreshableKey, refreshable, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            
            if refreshable {
                refreshControl = refreshControl ?? {
                    let refreshControl = UIRefreshControl()
                    refreshControl.addTarget(self, action: #selector(refresh(_:)), for: .valueChanged)
                    if #available(iOS 10.0, *) {
                        collectionView?.refreshControl = refreshControl
                    } else {
                        collectionView?.addSubview(refreshControl)
                    }
                    return refreshControl
                }()
            } else {
                refreshControl?.removeFromSuperview()
                refreshControl = nil
            }
        }
    }
    
    func refresh(_ sender: UIRefreshControl) {
        currentPage = 1
        sender.endRefreshing()
        delegate?.didRefresh(collectionView: collectionView!)
    }
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard let collectionView = collectionView, scrollView == collectionView, paginated else { return }
        let y = scrollView.contentOffset.y + scrollView.bounds.size.height - scrollView.contentInset.bottom
        let height = scrollView.contentSize.height
        let reloadDistance: CGFloat = 10
        if y > height + reloadDistance && !isLoading && hasNextPage {
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
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        if let layout = collectionView?.collectionViewLayout as? UICollectionViewFlowLayout {
            let isHorizontal = layout.scrollDirection == .horizontal
            let isRegular = traitCollection.horizontalSizeClass == .regular
            let spacing: CGFloat = isRegular ? 30 : 10
            
            if isHorizontal {
                layout.minimumLineSpacing = spacing
            } else {
                layout.minimumInteritemSpacing = spacing
            }
        }
    }
}
