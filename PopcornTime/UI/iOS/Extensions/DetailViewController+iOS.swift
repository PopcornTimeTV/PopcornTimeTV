

import Foundation
import PopcornKit

extension DetailViewController: UIViewControllerTransitioningDelegate {
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        scrollViewDidScroll(scrollView) // Update the hidden status of UINavigationBar.
        NotificationCenter.default.addObserver(self, selector: #selector(updateCastStatus), name: .gckCastStateDidChange, object: nil)
        updateCastStatus()
        
        
        scrollView.contentInset.bottom = tabBarController?.tabBar.frame.height ?? 0
    
        if transitionCoordinator?.viewController(forKey: .from) is PreloadTorrentViewController {
            self.scrollView.contentOffset.y = -self.view.bounds.height
            transitionCoordinator?.animate(alongsideTransition: { (context) in
                guard let tabBarFrame = self.tabBarController?.tabBar.frame else { return }
                
                let tabBarOffsetY = -tabBarFrame.size.height
                self.tabBarController?.tabBar.frame = tabBarFrame.offsetBy(dx: 0, dy: tabBarOffsetY)
                
                self.gradientView?.alpha = 1.0
                self.scrollView.contentOffset.y = -self.headerHeight
                
                self.view.layoutIfNeeded()
            }, completion: nil)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.isBackgroundHidden = false
        NotificationCenter.default.removeObserver(self)
        
        if transitionCoordinator?.viewController(forKey: .to) is PreloadTorrentViewController {
            transitionCoordinator?.animate(alongsideTransition: { (context) in
                guard let tabBarFrame = self.tabBarController?.tabBar.frame, let navigationBarFrame = self.navigationController?.navigationBar.frame else { return }
                
                let tabBarOffsetY = tabBarFrame.size.height
                let navigationOffsetY = -(navigationBarFrame.size.height + self.statusBarHeight)
                
                self.tabBarController?.tabBar.frame = tabBarFrame.offsetBy(dx: 0, dy: tabBarOffsetY)
                self.navigationController?.navigationBar.frame = navigationBarFrame.offsetBy(dx: 0, dy: navigationOffsetY)
                
                self.gradientView?.alpha = 0.0
                self.scrollView.contentOffset.y = -self.view.bounds.height
                
                self.view.layoutIfNeeded()
            }, completion: nil)
        }
    }
    
    func updateHeaderFrame() {
        var headerRect = CGRect(x: 0, y: 0, width: scrollView.bounds.width, height: headerHeight)
        if scrollView.contentOffset.y < -headerHeight {
            headerRect.size.height = -scrollView.contentOffset.y
        }
        
        backgroundImageView.frame = headerRect
    }
    
    func updateCastStatus() {
        castButton?.status = GCKCastContext.sharedInstance().castState
    }
    
    func showCastDevices() {
        performSegue(withIdentifier: "showCasts", sender: castButton)
    }
    
    func presentCastPlayer(_ media: Media, videoFilePath: URL) {
        dismiss(animated: true, completion: nil) // Close player view controller first.
        let castPlayerViewController = storyboard?.instantiateViewController(withIdentifier: "CastPlayerViewController") as! CastPlayerViewController
        castPlayerViewController.media = media
        castPlayerViewController.directory = videoFilePath.deletingLastPathComponent()
        present(castPlayerViewController, animated: true, completion: nil)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        updateHeaderFrame()
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        navigationController?.navigationBar.isBackgroundHidden = scrollView.contentOffset.y <= -44
        navigationController?.navigationBar.tintColor = scrollView.contentOffset.y <= -44 ? .white : .app
        updateHeaderFrame()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        let isCompact = traitCollection.horizontalSizeClass == .compact
        headerHeight = isCompact ? 240 : 315
        infoStackView.axis = isCompact ? .vertical : .horizontal
        infoStackView.alignment = isCompact ? .fill : .top
        [peopleCollectionViewController.collectionView, relatedCollectionViewController.collectionView].forEach({
            $0?.contentInset.left  = isCompact ? 14 : 26
            $0?.contentInset.right = isCompact ? 14 : 26
        })
        
        episodesCollectionViewController.collectionView?.contentInset.left  = isCompact ? 28 : 40
        episodesCollectionViewController.collectionView?.contentInset.right = isCompact ? 28 : 40
        
        for constraint in compactConstraints {
            constraint.priority = isCompact ? 999 : 240
        }
        for constraint in regularConstraints {
            constraint.priority = isCompact ? 240 : 999
        }
    }
    
    // MARK: - Presentation
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        if presented is PreloadTorrentViewController {
            return PreloadTorrentViewControllerAnimatedTransitioning(isPresenting: true)
        }
        return nil
        
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        if dismissed is PreloadTorrentViewController {
            return PreloadTorrentViewControllerAnimatedTransitioning(isPresenting: false)
        }
        return nil
    }
}
