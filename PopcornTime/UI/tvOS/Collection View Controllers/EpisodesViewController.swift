

import Foundation
import struct PopcornKit.Episode
import AlamofireImage
import PopcornTorrent

typealias EpisodesCollectionViewController = EpisodesViewController // Keep Xcode happy

class EpisodesViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UIViewControllerTransitioningDelegate, PTTorrentDownloadManagerListener {
    
    var dataSource: [Episode] = []
    
    @IBOutlet var titleView: UIView!
    @IBOutlet var titleImageView: UIImageView!
    @IBOutlet var titleLabel: UILabel!
    
    @IBOutlet var numberOfEpisodesLabel: UILabel!
    @IBOutlet var collectionView: UICollectionView!
    
    @IBOutlet var episodeSummaryTextView: TVExpandableTextView!
    @IBOutlet var episodeTitleLabel: UILabel!
    @IBOutlet var episodeInfoTextView: UITextView!
    @IBOutlet var downloadButton: DownloadButton!
    
    @IBOutlet var episodeTitleLabelTopConstraint: NSLayoutConstraint!
    
    let summaryFocusGuide = UIFocusGuide()
    let topFocusGuide = UIFocusGuide()
    var focusIndexPath = IndexPath(row: 0, section: 0)
    
    var isDark = true {
        didSet {
            guard isDark != oldValue else { return }
            
            let colorPallete: ColorPallete = isDark ? .light : .dark
            
            episodeTitleLabel.textColor = colorPallete.primary
            episodeInfoTextView.textColor = colorPallete.primary
            titleLabel.textColor = colorPallete.primary
            numberOfEpisodesLabel.textColor = colorPallete.secondary
            
            episodeSummaryTextView.isDark = isDark
            downloadButton.isDark = isDark
            
            collectionView?.reloadData()
        }
    }
    
    var itemViewController: ItemViewController? {
        get {
            if let parent = parent as? DetailViewController {
                return parent.itemViewController
            }
            return nil
        } set(vc) {
            if let parent = parent as? DetailViewController {
                parent.itemViewController = vc
            }
        }
    }
    
    var environmentsToFocus: [UIFocusEnvironment] {
        get {
            return itemViewController?.environmentsToFocus ?? []
        } set(environments) {
            itemViewController?.environmentsToFocus = environments
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        titleLabel.text = dataSource.first?.show?.title
        episodeSummaryTextView.buttonWasPressed = moreButtonWasPressed
        PTTorrentDownloadManager.shared().add(self)
        downloadButton.addTarget(self, action: #selector(stopDownload(_:)), for: .applicationReserved)
        
        view.addLayoutGuide(summaryFocusGuide)
        view.addLayoutGuide(topFocusGuide)
        
        summaryFocusGuide.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        summaryFocusGuide.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        summaryFocusGuide.bottomAnchor.constraint(equalTo: episodeTitleLabel.topAnchor).isActive = true
        summaryFocusGuide.topAnchor.constraint(equalTo: collectionView.bottomAnchor).isActive = true
        
        summaryFocusGuide.preferredFocusEnvironments = [downloadButton, episodeSummaryTextView]
        
        topFocusGuide.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        topFocusGuide.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        topFocusGuide.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        topFocusGuide.bottomAnchor.constraint(equalTo: collectionView.topAnchor).isActive = true
        
        topFocusGuide.preferredFocusEnvironments = [collectionView]
    }
    
    func moreButtonWasPressed(text: String?) {
        let viewController = UIStoryboard.main.instantiateViewController(withIdentifier: "TVDescriptionViewController") as! TVDescriptionViewController
        viewController.loadView()
        viewController.titleLabel.text = dataSource[focusIndexPath.row].title
        viewController.textView.text = text
        viewController.transitioningDelegate = self
        viewController.modalPresentationStyle = .custom
        present(viewController, animated: true)
    }
    
    @objc func stopDownload(_ sender: DownloadButton) {
        guard let media = dataSource[safe: focusIndexPath.row],
            let download = media.associatedDownload else { return }
        AppDelegate.shared.downloadButton(sender, wantsToStop: download)
    }
    
    @IBAction func download(_ sender: DownloadButton) {
        let media = dataSource[focusIndexPath.row]
        
        if sender.downloadState == .normal {
            AppDelegate.shared.chooseQuality(sender, media: media) { (torrent) in
                PTTorrentDownloadManager.shared().startDownloading(fromFileOrMagnetLink: torrent.url, mediaMetadata: media.mediaItemDictionary)
                sender.downloadState = .pending
            }
        } else if let download = media.associatedDownload {
            AppDelegate.shared.downloadButton(sender, wasPressedWith: download)
        }
    }
    
    // MARK: - PTTorrentDownloadManagerListener
    
    func torrentStatusDidChange(_ torrentStatus: PTTorrentStatus, for download: PTTorrentDownload) {
        guard let media = dataSource[safe: focusIndexPath.row],
            download == media.associatedDownload else { return }
        downloadButton.progress = torrentStatus.totalProgress
    }
    
    func downloadStatusDidChange(_ downloadStatus: PTTorrentDownloadStatus, for download: PTTorrentDownload) {
        guard let media = dataSource[safe: focusIndexPath.row],
            download == media.associatedDownload else { return }
        downloadButton.downloadState = DownloadButton.ButtonState(downloadStatus)
    }
    
    func downloadDidFail(_ download: PTTorrentDownload, withError error: Error) {
        guard let media = dataSource[safe: focusIndexPath.row],
            download == media.associatedDownload else { return }
        AppDelegate.shared.download(download, failedWith: error)
    }
    
    deinit {
        PTTorrentDownloadManager.shared().remove(self)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        collectionView.setNeedsFocusUpdate()
        collectionView.updateFocusIfNeeded()
        
        collectionView.reloadData()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if collectionView.numberOfItems(inSection: 0) == 0 {
            preferredContentSize = .zero
        } else {
            preferredContentSize = CGSize(width: view.bounds.width, height: 750 + episodeTitleLabelTopConstraint.constant)
        }
    }
    
    // MARK: - Collection view data source
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let value = dataSource.count
        let singular = value == 1
        numberOfEpisodesLabel.text = "\(NumberFormatter.localizedString(from: NSNumber(value: value), number: .none)) \(singular ? "Episode".localized : "Episodes".localized)"
        return value
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! EpisodeCollectionViewCell
        
        let episode = dataSource[indexPath.row]
        
        let episodeNumber = NumberFormatter.localizedString(from: NSNumber(value: episode.episode), number: .none)
        cell.titleLabel.text = "\(episodeNumber). \(episode.title)"
        cell.id = episode.id
        cell.isDark = isDark
        
        if let image = episode.smallBackgroundImage, let url = URL(string: image) {
            cell.imageView.af_setImage(withURL: url, placeholderImage: UIImage(named: "Episode Placeholder"), imageTransition: .crossDissolve(.default)) { _ in
                cell.setNeedsDisplay()
            }
        } else {
            cell.imageView.image = UIImage(named: "Episode Placeholder")
        }
        
        return cell
    }
    
    // MARK: - Collection view delegate
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let media = dataSource[indexPath.row]
        AppDelegate.shared.chooseQuality(nil, media: media) { (torrent) in
            AppDelegate.shared.play(media, torrent: torrent)
        }
        
        focusIndexPath = indexPath
    }
    
    func indexPathForPreferredFocusedView(in collectionView: UICollectionView) -> IndexPath? {
        guard dataSource.count > focusIndexPath.row
        else {
            focusIndexPath.row = dataSource.count - 1
            return focusIndexPath
        }
        return focusIndexPath
    }
    
    
    func collectionView(_ collectionView: UICollectionView, didUpdateFocusIn context: UICollectionViewFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        
        var shouldUpdateView = false
        summaryFocusGuide.preferredFocusEnvironments = [downloadButton, episodeSummaryTextView]
        topFocusGuide.preferredFocusEnvironments = itemViewController?.visibleButtons.compactMap({$0})
        environmentsToFocus = [context.nextFocusedView].compactMap({$0})
        
        
        if let next = context.nextFocusedIndexPath {
            let episode = dataSource[next.row]
            
            focusIndexPath = next
            
            let downloadStatus = episode.associatedDownload?.downloadStatus ?? .failed
            downloadButton.downloadState = DownloadButton.ButtonState(downloadStatus)
            downloadButton.progress = episode.associatedDownload?.torrentStatus.totalProgress ?? 0
            
            episodeSummaryTextView.text = episode.summary
            episodeTitleLabel.text = episode.title
            
            let airDateString = DateFormatter.localizedString(from: episode.firstAirDate, dateStyle: .medium, timeStyle: .none)
            
            let showGenre = episode.show?.genres.first?.localizedCapitalized.localized ?? ""
            episodeInfoTextView.text = "\(airDateString) \n \(showGenre)"
            
            if context.previouslyFocusedIndexPath == nil // Collection view has just gained focus, expand UI
            {
                episodeTitleLabelTopConstraint.constant = 140
                numberOfEpisodesLabel.font = .preferredFont(forTextStyle: .headline)
                shouldUpdateView = true
                
                // View should always be at the centre of the screen.
                if let parent = parent as? DetailViewController {
                    let size = parent.scrollView.bounds.size
                    let origin = parent.scrollView.convert(view.frame.origin, from: view)
                    UIView.animate(withDuration: 2.2, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 4, options: [.curveEaseOut], animations: {
                        parent.scrollView.scrollRectToVisible(CGRect(origin: origin, size: size), animated: false)
                    })
                }
            }
        } else if let next = context.nextFocusedView, let itemViewController = itemViewController, next == itemViewController.summaryTextView || !itemViewController.visibleButtons.filter({$0 == next}).isEmpty // Collection view is loosing focus, shrink UI
        {
            episodeTitleLabelTopConstraint.constant = 15
            numberOfEpisodesLabel.font = .preferredFont(forTextStyle: .callout)
            topFocusGuide.preferredFocusEnvironments = [collectionView]
            shouldUpdateView = true
        } else if let next = context.nextFocusedView, let cell = context.previouslyFocusedView as? UICollectionViewCell, (next == episodeSummaryTextView || next == downloadButton) {
            summaryFocusGuide.preferredFocusEnvironments = [cell]
        }
        
        if shouldUpdateView {
            coordinator.addCoordinatedAnimations({ [unowned self] in
                if context.previouslyFocusedIndexPath == nil {
                    self.titleView.alpha = 1.0
                } else {
                    self.titleView.alpha = 0.0
                }
                self.view.layoutIfNeeded()
            })
        }
    }
    
    // MARK: - Presentation
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        if presented is TVDescriptionViewController {
            return TVBlurOverCurrentContextAnimatedTransitioning(isPresenting: true)
        }
        return nil
        
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        if dismissed is TVDescriptionViewController {
            return TVBlurOverCurrentContextAnimatedTransitioning(isPresenting: false)
        }
        return nil
    }
}
