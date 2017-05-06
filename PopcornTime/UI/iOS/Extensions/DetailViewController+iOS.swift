

import Foundation
import protocol PopcornKit.Media

extension DetailViewController {
    
    @IBAction func toggleWatchlist(_ sender: UIButton) {
        currentItem.isAddedToWatchlist = !currentItem.isAddedToWatchlist
        sender.setImage(watchlistButtonImage, for: .normal)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        watchedButton.setImage(watchedButtonImage, for: .normal)
        watchlistButton.setImage(watchlistButtonImage, for: .normal)
        
        NotificationCenter.default.addObserver(self, selector: #selector(updateCastStatus), name: .gckCastStateDidChange, object: nil)
        updateCastStatus()
        scrollViewDidScroll(scrollView) // Update the hidden status of UINavigationBar.
        
        scrollView.contentInset.bottom = tabBarController?.tabBar.frame.height ?? 0
    
        if transitionCoordinator?.viewController(forKey: .from) is PreloadTorrentViewController {
            self.scrollView.contentOffset.y = -self.view.bounds.height
            transitionCoordinator?.animate(alongsideTransition: { [unowned self] (context) in
                guard let tabBarFrame = self.tabBarController?.tabBar.frame else { return }
                
                let tabBarOffsetY = -tabBarFrame.size.height
                self.tabBarController?.tabBar.frame = tabBarFrame.offsetBy(dx: 0, dy: tabBarOffsetY)
                
                self.gradientView?.alpha = 1.0
                self.scrollView.contentOffset.y = -self.headerHeight
                
                self.view.layoutIfNeeded()
            })
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.isBackgroundHidden = false
        NotificationCenter.default.removeObserver(self)
        
        transitionCoordinator?.animate(alongsideTransition: nil) { [weak self] (context) in
            guard let `self` = self, context.isCancelled else { return }
            self.scrollViewDidScroll(self.scrollView) // When interactive pop gesture is cancelled, update hidden status of UINavigationBar.
        }
        
        if transitionCoordinator?.viewController(forKey: .to) is PreloadTorrentViewController {
            transitionCoordinator?.animate(alongsideTransition: { [unowned self] (context) in
                guard let tabBarFrame = self.tabBarController?.tabBar.frame, let navigationBarFrame = self.navigationController?.navigationBar.frame else { return }
                
                let tabBarOffsetY = tabBarFrame.size.height
                let navigationOffsetY = -(navigationBarFrame.size.height + self.statusBarHeight)
                
                self.tabBarController?.tabBar.frame = tabBarFrame.offsetBy(dx: 0, dy: tabBarOffsetY)
                self.navigationController?.navigationBar.frame = navigationBarFrame.offsetBy(dx: 0, dy: navigationOffsetY)
                
                self.gradientView?.alpha = 0.0
                self.scrollView.contentOffset.y = -self.view.bounds.height
                
                self.view.layoutIfNeeded()
            })
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
    
    // MARK: - PCTPlayerViewControllerDelegate
    
    func playerViewControllerPresentCastPlayer(_ playerViewController: PCTPlayerViewController) {
        dismiss(animated: true) // Close player view controller first.
        let castPlayerViewController = storyboard?.instantiateViewController(withIdentifier: "CastPlayerViewController") as! CastPlayerViewController
        castPlayerViewController.media = playerViewController.media
        castPlayerViewController.localPathToMedia = playerViewController.localPathToMedia
        castPlayerViewController.directory = playerViewController.directory
        castPlayerViewController.url = playerViewController.url
        castPlayerViewController.startPosition = TimeInterval(playerViewController.progressBar.progress)
        present(castPlayerViewController, animated: true)
    }
}
