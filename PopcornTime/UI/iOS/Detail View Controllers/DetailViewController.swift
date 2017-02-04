

import Foundation
import UIKit
import XCDYouTubeKit
import AlamofireImage
import FloatRatingView
import PopcornTorrent
import PopcornKit

class DetailViewController: UIViewController, PCTPlayerViewControllerDelegate, CollectionViewControllerDelegate, UIScrollViewDelegate, InfoViewControllerDelegate, UIViewControllerTransitioningDelegate {

    @IBOutlet var castButton: CastIconBarButtonItem!
    @IBOutlet var seasonsLabel: UILabel!
    @IBOutlet var moreSeasonsButton: UIButton!

    @IBOutlet var scrollView: UIScrollView!
    @IBOutlet var infoStackView: UIStackView!
    @IBOutlet var backgroundImageView: UIImageView!
    @IBOutlet var gradientView: GradientView!
    
    var relatedCollectionViewController: CollectionViewController!
    var castCollectionViewController: CollectionViewController!
    var informationCollectionViewController: DescriptionCollectionViewController!
    var accessibilityCollectionViewController: DescriptionCollectionViewController!
    var episodesCollectionViewController: EpisodesCollectionViewController!
    
    var currentItem: Media!
    var currentType: Trakt.MediaType {
        return currentItem is Movie ? .movies : .shows
    }
    var headerHeight: CGFloat = 0 {
        didSet {
            scrollView.contentInset.top = headerHeight
        }
    }
    var currentSeason = -1
    
    
    @IBOutlet var relatedViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet var castViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet var episodesViewHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet var relatedCollectionViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet var castCollectionViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet var informationCollectionViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet var accessibilityCollectionViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet var episodesCollectionViewHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet var compactConstraints: [NSLayoutConstraint]!
    @IBOutlet var regularConstraints: [NSLayoutConstraint]!
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        scrollViewDidScroll(scrollView) // Update the hidden status of UINavigationBar.
        NotificationCenter.default.addObserver(self, selector: #selector(updateCastStatus), name: .gckCastStateDidChange, object: nil)
        updateCastStatus()
        
        if transitionCoordinator?.viewController(forKey: .from) is LoadingViewController {
            self.scrollView.contentOffset.y = -self.view.bounds.height
            transitionCoordinator?.animate(alongsideTransition: { (context) in
                guard let tabBarFrame = self.tabBarController?.tabBar.frame else { return }
                
                let tabBarOffsetY = -tabBarFrame.size.height
                self.tabBarController?.tabBar.frame = tabBarFrame.offsetBy(dx: 0, dy: tabBarOffsetY)
                
                self.gradientView.alpha = 1.0
                self.scrollView.contentOffset.y = -self.headerHeight
                
                self.view.layoutIfNeeded()
            }, completion: nil)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.isBackgroundHidden = false
        NotificationCenter.default.removeObserver(self)
        
        if transitionCoordinator?.viewController(forKey: .to) is LoadingViewController {
            transitionCoordinator?.animate(alongsideTransition: { (context) in
                guard let tabBarFrame = self.tabBarController?.tabBar.frame, let navigationBarFrame = self.navigationController?.navigationBar.frame else { return }
                
                let tabBarOffsetY = tabBarFrame.size.height
                let navigationOffsetY = -(navigationBarFrame.size.height + self.statusBarHeight)
                
                self.tabBarController?.tabBar.frame = tabBarFrame.offsetBy(dx: 0, dy: tabBarOffsetY)
                self.navigationController?.navigationBar.frame = navigationBarFrame.offsetBy(dx: 0, dy: navigationOffsetY)
                
                self.gradientView.alpha = 0.0
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = currentItem.title
        
        scrollView.contentInset.bottom = tabBarController?.tabBar.frame.height ?? 0
        
        if let image = currentItem.largeBackgroundImage, let url = URL(string: image) {
            backgroundImageView.af_setImage(withURL: url)
        }
        
        TMDBManager.shared.getLogo(forMediaOfType: currentType, id: currentItem.id) { [weak self] (image, error) in
            if let image = image, let url = URL(string: image), let `self` = self {
                let imageView = UIImageView(frame: CGRect(origin: .zero, size: CGSize(width: .max, height: 40)))
                imageView.clipsToBounds = true
                imageView.contentMode = .scaleAspectFit
                imageView.af_setImage(withURL: url) { response in
                    guard response.result.isSuccess else { return }
                    self.navigationItem.titleView = imageView
                }
            }
        }
    }
    
    func loadMedia(id: String, completion: @escaping (Media?, NSError?) -> Void) { }
    
    func updateCastStatus() {
        (castButton.customView as! CastIconButton).status = GCKCastContext.sharedInstance().castState
    }
    
    @IBAction func changeSeason(_ sender: UIButton) { }
    
    func chooseQuality(_ sender: UIButton) {
        guard currentItem.torrents.count > 1 else {
            if let torrent = currentItem.torrents.first {
                play(currentItem, torrent: torrent)
            } else {
                let vc = UIAlertController(title: "No torrents found", message: "Torrents could not be found for the specified media.", preferredStyle: .alert)
                vc.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                present(vc, animated: true, completion: nil)
            }
            return
        }
        
        let vc = UIAlertController(title: "Choose Quality", message: "Choose a quality to stream.", preferredStyle: .actionSheet, blurStyle: .dark)
        
        for torrent in currentItem.torrents {
            vc.addAction(UIAlertAction(title: torrent.quality, style: .default, handler: { (action) in
                self.play(self.currentItem, torrent: torrent)
            }))
        }
        
        vc.popoverPresentationController?.sourceView = sender
        
        present(vc, animated: true, completion: nil)
    }
    
    func play(_ media: Media, torrent: Torrent) {
        if UserDefaults.standard.bool(forKey: "streamOnCellular") || (UIApplication.shared.delegate as! AppDelegate).reachability!.isReachableViaWiFi() {
            
            dismiss(animated: false, completion: nil) // Make sure we're not already presenting a view controller.
            
            var media = media
            
            let currentProgress = media is Movie ? WatchedlistManager<Movie>.movie.currentProgress(media.id) : WatchedlistManager<Episode>.episode.currentProgress(media.id)
            var nextEpisode: Episode?
            
            let loadingViewController = storyboard?.instantiateViewController(withIdentifier: "LoadingViewController") as! LoadingViewController
            loadingViewController.backgroundImageString = media.largeBackgroundImage
            loadingViewController.mediaTitle = media.title
            loadingViewController.transitioningDelegate = self
            
            if let episode = media as? Episode {
                
                loadingViewController.backgroundImageString = episode.show.largeBackgroundImage
                var episodesLeftInShow = [Episode]()
                
                for season in episode.show.seasonNumbers where season >= currentSeason {
                    episodesLeftInShow += episode.show.episodes.filter({$0.season == season}).sorted(by: {$0.0.episode < $0.1.episode})
                }
                
                let index = episodesLeftInShow.index(of: episode)!
                episodesLeftInShow.removeFirst(index + 1)
                
                nextEpisode = !episodesLeftInShow.isEmpty ? episodesLeftInShow.removeFirst() : nil
                nextEpisode?.show = episode.show
            }
            
            present(loadingViewController, animated: true)
            
            let error: (String) -> Void = { (errorMessage) in
                let vc = UIAlertController(title: "Error", message: errorMessage, preferredStyle: .alert)
                vc.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                self.present(vc, animated: true)
            }
            
            let finishedLoading: (LoadingViewController, UIViewController) -> Void = { (loadingVc, playerVc) in
                self.dismiss(animated: true, completion: nil)
                self.present(playerVc, animated: true)
            }
            
            let playViewController = storyboard?.instantiateViewController(withIdentifier: "PCTPlayerViewController") as! PCTPlayerViewController
            playViewController.delegate = self
            
            media.getSubtitles(forId: media.id) { subtitles in
                media.subtitles = subtitles
                
                if let perferredLanguage = SubtitleSettings().language {
                    media.currentSubtitle = media.subtitles.first(where: {$0.language == perferredLanguage})
                }
                
                media.play(fromFileOrMagnetLink: torrent.magnet ?? torrent.url, nextEpisodeInSeries: nextEpisode, loadingViewController: loadingViewController, playViewController: playViewController, progress: currentProgress, errorBlock: error, finishedLoadingBlock: finishedLoading)
            }
        } else {
            let errorAlert = UIAlertController(title: "Cellular Data is turned off for streaming", message: nil, preferredStyle: .alert)
            errorAlert.addAction(UIAlertAction(title: "Turn On", style: .default, handler: { [weak self] _ in
                UserDefaults.standard.set(true, forKey: "streamOnCellular")
                self?.play(media, torrent: torrent)
            }))
            errorAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            present(errorAlert, animated: true, completion: nil)
        }
    }
    
    func presentCastPlayer(_ media: Media, videoFilePath: URL, startPosition: TimeInterval) {
        
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
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "embedEpisodes", let vc = segue.destination as? EpisodesCollectionViewController {
            episodesCollectionViewController = vc
        } else if let vc = segue.destination as? DescriptionCollectionViewController, segue.identifier == "embedAccessibility" {
            vc.headerTitle = "Accessibility"
            
            let key = UIImage(named: "SDH")!.colored(.white).attributed
            let value = "Subtitles for the deaf and Hard of Hearing (SDH) refer to subtitles in the original lanuage with the addition of relevant non-dialog information."
            
            vc.dataSource = [(key, value)]
            
            accessibilityCollectionViewController = vc
        } else if let vc = segue.destination as? CollectionViewController {
            vc.delegate = self
            
            let layout = vc.collectionView?.collectionViewLayout as? UICollectionViewFlowLayout
            layout?.scrollDirection = .horizontal
            layout?.minimumLineSpacing = 30
            vc.collectionView?.showsHorizontalScrollIndicator = false
            
            vc.collectionView?.reloadData()
        }
    }
    
    override func preferredContentSizeDidChange(forChildContentContainer container: UIContentContainer) {
        let height = container.preferredContentSize.height
        let vc     = container as? UIViewController
        
        if vc == relatedCollectionViewController {
            relatedCollectionViewHeightConstraint.constant = height
            relatedViewHeightConstraint.priority = height == 0 ? 999 : 1
        } else if vc == castCollectionViewController {
            castCollectionViewHeightConstraint.constant = height
            castViewHeightConstraint.priority = height == 0 ? 999 : 1
        } else if vc == episodesCollectionViewController {
            episodesCollectionViewHeightConstraint.constant = height
            episodesViewHeightConstraint.priority = height == 0 ? 999 : 1
        } else if vc == informationCollectionViewController {
            informationCollectionViewHeightConstraint.constant = height
        } else if vc == accessibilityCollectionViewController {
            accessibilityCollectionViewHeightConstraint.constant = height
        }
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        let isCompact = traitCollection.horizontalSizeClass == .compact
        headerHeight = isCompact ? 240 : 315
        infoStackView.axis = isCompact ? .vertical : .horizontal
        infoStackView.alignment = isCompact ? .fill : .top
        [castCollectionViewController.collectionView, relatedCollectionViewController.collectionView].forEach({
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
        if presented is LoadingViewController {
            return LoadingViewAnimatedTransitioning(isPresenting: true)
        }
        return nil
        
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        if dismissed is LoadingViewController {
            return LoadingViewAnimatedTransitioning(isPresenting: false)
        }
        return nil
    }
}
