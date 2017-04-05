

import Foundation
import UIKit
import AlamofireImage
import PopcornTorrent
import PopcornKit

class DetailViewController: UIViewController, PCTPlayerViewControllerDelegate, CollectionViewControllerDelegate, UIScrollViewDelegate, UIViewControllerTransitioningDelegate {
    
    
    #if os(iOS)

    @IBOutlet var castButton: CastIconButton?
    @IBOutlet var watchlistButton: UIButton?
    @IBOutlet var watchedButton: UIButton?
    
    @IBOutlet var moreSeasonsButton: UIButton?
    @IBOutlet var seasonsLabel: UILabel!
    
    var headerHeight: CGFloat = 0 {
        didSet {
            scrollView.contentInset.top = headerHeight
        }
    }
    
    #elseif os(tvOS)
    
    var seasonsLabel: UILabel {
        get {
            return itemViewController.titleLabel
        } set (label) {
            itemViewController.titleLabel = label
        }
    }
    
    #endif
    
    // tvOS Exclusive
    @IBOutlet var titleImageView: UIImageView?
    @IBOutlet var titleLabel: UILabel?
    @IBOutlet var backgroundVisualEffectView: UIVisualEffectView?
    
    // iOS Exclusive 
    @IBOutlet var gradientView: GradientView?

    @IBOutlet var scrollView: UIScrollView!
    @IBOutlet var infoStackView: UIStackView!
    @IBOutlet var backgroundImageView: UIImageView!
    
    @IBOutlet var compactConstraints: [NSLayoutConstraint] = []
    @IBOutlet var regularConstraints: [NSLayoutConstraint] = []
    
    
    // MARK: - Container view controllers
    
    var itemViewController: ItemViewController!
    var relatedCollectionViewController: CollectionViewController!
    var peopleCollectionViewController: CollectionViewController!
    var informationDescriptionCollectionViewController: DescriptionCollectionViewController!
    var accessibilityDescriptionCollectionViewController: DescriptionCollectionViewController!
    var episodesCollectionViewController: EpisodesCollectionViewController!
    
    // MARK: - Container view height constraints
    
    @IBOutlet var relatedContainerViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet var peopleContainerViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet var episodesContainerViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet var informationContainerViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet var accessibilityContainerViewHeightConstraint: NSLayoutConstraint!
    
    var currentItem: Media!
    var currentSeason = -1
    
    override dynamic func viewDidLoad() {
        super.viewDidLoad()
        
        #if os(iOS)
            
            watchlistButton?.setImage(watchlistButtonImage, for: .normal)
            
        #elseif os(tvOS)
            
            let focusButtonsGuide = UIFocusGuide()
            view.addLayoutGuide(focusButtonsGuide)
            
            focusButtonsGuide.topAnchor.constraint(equalTo: itemViewController.view.bottomAnchor).isActive = true
            focusButtonsGuide.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
            focusButtonsGuide.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
            focusButtonsGuide.bottomAnchor.constraint(equalTo: backgroundVisualEffectView!.topAnchor).isActive = true
            
            focusButtonsGuide.preferredFocusEnvironments = itemViewController.visibleButtons
            
        #endif
        
        navigationItem.title = currentItem.title
        titleLabel?.text = currentItem.title
        
        if let image = currentItem.largeBackgroundImage, let url = URL(string: image) {
            backgroundImageView.af_setImage(withURL: url)
        }
        
        let completion: (String?, NSError?) -> Void = { [weak self] (image, error) in
            guard let image = image, let url = URL(string: image), let `self` = self else { return }
            let imageView = UIImageView(frame: CGRect(origin: .zero, size: CGSize(width: .max, height: 40)))
            imageView.clipsToBounds = true
            imageView.contentMode = .scaleAspectFit
            imageView.af_setImage(withURL: url) { response in
                guard response.result.isSuccess else { return }
                #if os(tvOS)
                    self.titleImageView?.image = response.result.value
                    self.titleLabel?.isHidden = true
                    
                    self.episodesCollectionViewController.titleImageView.image = response.result.value
                    self.episodesCollectionViewController.titleLabel.isHidden = true
                #elseif os(iOS)
                    self.navigationItem.titleView = imageView
                #endif
            }
        }
        
        if let movie = currentItem as? Movie {
            TMDBManager.shared.getLogo(forMediaOfType: .movies, id: movie.id, completion: completion)
        } else if let show = currentItem as? Show {
            TMDBManager.shared.getLogo(forMediaOfType: .shows, id: show.tvdbId, completion: completion)
        }
    }
    
    func loadMedia(id: String, completion: @escaping (Media?, NSError?) -> Void) { }
    
    // MARK: - Collection view controller delegate
    
    func minItemSize(forCellIn collectionView: UICollectionView, at indexPath: IndexPath) -> CGSize? {
        if collectionView === peopleCollectionViewController.collectionView {
            return UIDevice.current.userInterfaceIdiom == .tv ? CGSize(width: 250, height: 360) : CGSize(width: 108, height: 180)
        } else if collectionView === relatedCollectionViewController.collectionView && UIDevice.current.userInterfaceIdiom == .tv {
            return CGSize(width: 150, height: 304)
        }
        return nil
    }
    
    // MARK: - Play media
    
    func chooseQuality(_ sender: Any?, media: Media) {
        
        if let quality = UserDefaults.standard.string(forKey: "autoSelectQuality") {
            let sorted  = media.torrents.sorted(by: <)
            let torrent = quality == "Highest".localized ? sorted.last! : sorted.first!
            
            return play(media, torrent: torrent)
        }
        
        guard media.torrents.count > 1 else {
            if let torrent = media.torrents.first {
                play(media, torrent: torrent)
            } else {
                let vc = UIAlertController(title: "No torrents found".localized, message: "Torrents could not be found for the specified media.".localized, preferredStyle: .alert)
                vc.addAction(UIAlertAction(title: "OK".localized, style: .default, handler: nil))
                vc.show()
            }
            return
        }
        
        let style: UIAlertControllerStyle = sender == nil ? .alert : .actionSheet
        let blurStyle: UIBlurEffectStyle  = style == .alert ? .extraLight : .dark
        let vc = UIAlertController(title: "Choose Quality".localized, message: "Choose a quality to stream.".localized, preferredStyle: style, blurStyle: blurStyle)
        
        for torrent in media.torrents {
            vc.addAction(UIAlertAction(title: torrent.quality, style: .default, handler: { (action) in
                self.play(media, torrent: torrent)
            }))
        }
        
        vc.addAction(UIAlertAction(title: "Cancel".localized, style: .cancel, handler: nil))
        
        if let sender = sender as? UIView {
            vc.popoverPresentationController?.sourceView = sender
        }
        vc.view.tintColor = .app
        
        vc.show()
    }
    
    func play(_ media: Media, torrent: Torrent) {
        if UserDefaults.standard.bool(forKey: "streamOnCellular") || (UIApplication.shared.delegate as! AppDelegate).reachability.isReachableViaWiFi() {
            
            // Make sure we're not already presenting a view controller.
            if presentedViewController != nil {
                dismiss(animated: false)
            }
            
            let storyboard = UIStoryboard.main
            var media = media
            
            let currentProgress = media is Movie ? WatchedlistManager<Movie>.movie.currentProgress(media.id) : WatchedlistManager<Episode>.episode.currentProgress(media.id)
            var nextEpisode: Episode?
            
            let loadingViewController = storyboard.instantiateViewController(withIdentifier: "PreloadTorrentViewController") as! PreloadTorrentViewController
            loadingViewController.transitioningDelegate = self
            loadingViewController.loadView()
            
            let backgroundImage: String?
            
            if let episode = media as? Episode {
                backgroundImage = episode.show.largeBackgroundImage
                var episodesLeftInShow = [Episode]()
                
                for season in episode.show.seasonNumbers where season >= currentSeason {
                    episodesLeftInShow += episode.show.episodes.filter({$0.season == season}).sorted(by: {$0.0.episode < $0.1.episode})
                }
                
                let index = episodesLeftInShow.index(of: episode)!
                episodesLeftInShow.removeFirst(index + 1)
                
                nextEpisode = !episodesLeftInShow.isEmpty ? episodesLeftInShow.removeFirst() : nil
                nextEpisode?.show = episode.show
            } else {
                backgroundImage = media.largeBackgroundImage
            }
            
            if let image = backgroundImage, let url = URL(string: image) {
                loadingViewController.backgroundImageView?.af_setImage(withURL: url)
            }
            loadingViewController.titleLabel.text = media.title
            
            present(loadingViewController, animated: true)
            
            let error: (String) -> Void = { (errorMessage) in
                if self.presentedViewController != nil {
                    self.dismiss(animated: false)
                }
                let vc = UIAlertController(title: "Error".localized, message: errorMessage, preferredStyle: .alert)
                vc.addAction(UIAlertAction(title: "OK".localized, style: .cancel, handler: nil))
                self.present(vc, animated: true)
            }
            
            let finishedLoading: (PreloadTorrentViewController, UIViewController) -> Void = { (loadingVc, playerVc) in
                let flag = UIDevice.current.userInterfaceIdiom != .tv
                self.dismiss(animated: flag)
                self.present(playerVc, animated: flag)
            }
            
            media.getSubtitles(forId: media.id) { subtitles in
                guard !loadingViewController.shouldCancelStreaming else { return }
                
                media.subtitles = subtitles
                
                #if os(iOS)
                    
                    if GCKCastContext.sharedInstance().castState == .connected {
                        let playViewController = storyboard.instantiateViewController(withIdentifier: "CastPlayerViewController") as! CastPlayerViewController
                        media.playOnChromecast(fromFileOrMagnetLink: torrent.url, loadingViewController: loadingViewController, playViewController: playViewController, progress: currentProgress, errorBlock: error, finishedLoadingBlock: finishedLoading)
                        return
                    }
                    
                #endif
                
                let playViewController = storyboard.instantiateViewController(withIdentifier: "PCTPlayerViewController") as! PCTPlayerViewController
                playViewController.delegate = self
                media.play(fromFileOrMagnetLink: torrent.url, nextEpisodeInSeries: nextEpisode, loadingViewController: loadingViewController, playViewController: playViewController, progress: currentProgress, errorBlock: error, finishedLoadingBlock: finishedLoading)
            }
        } else {
            let errorAlert = UIAlertController(title: "Cellular Data is turned off for streaming".localized, message: nil, preferredStyle: .alert)
            errorAlert.addAction(UIAlertAction(title: "Turn On".localized, style: .default, handler: { [weak self] _ in
                UserDefaults.standard.set(true, forKey: "streamOnCellular")
                self?.play(media, torrent: torrent)
            }))
            errorAlert.addAction(UIAlertAction(title: "Cancel".localized, style: .cancel, handler: nil))
            errorAlert.show()
        }
    }
    
    // MARK: - PCTPlayerViewControllerDelegate
    
    func playNext(_ episode: Episode) {
        chooseQuality(nil, media: episode)
    }
    
    // MARK: Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        #if os(iOS)
            if segue.identifier == "showCastDevices", let vc = segue.destination as? UINavigationController, vc.viewControllers.first is GoogleCastTableViewController, let sender = sender as? CastIconButton {
                vc.popoverPresentationController?.sourceRect = sender.bounds
            }
        #endif
        if segue.identifier == "embedItem", let vc = segue.destination as? ItemViewController {
            itemViewController = vc
            itemViewController.media = currentItem
            vc.view.translatesAutoresizingMaskIntoConstraints = false
        } else if segue.identifier == "embedEpisodes", let vc = segue.destination as? EpisodesCollectionViewController {
            episodesCollectionViewController = vc
        } else if let vc = segue.destination as? DescriptionCollectionViewController, segue.identifier == "embedAccessibility" {
            vc.headerTitle = "Accessibility".localized
            
            let key = UIImage(named: "SDH")!.colored(.white)!.attributed
            let value = "Subtitles for the deaf and Hard of Hearing (SDH) refer to subtitles in the original lanuage with the addition of relevant non-dialog information.".localized
            
            vc.dataSource = [(key, value)]
            
            accessibilityDescriptionCollectionViewController = vc
        } else if let vc = segue.destination as? CollectionViewController {
            vc.delegate = self
            
            let layout = vc.collectionView?.collectionViewLayout as? UICollectionViewFlowLayout
            layout?.scrollDirection = .horizontal
            layout?.minimumLineSpacing = 48
            layout?.sectionInset.top = 0
            layout?.sectionInset.bottom = 0
        }
    }
    
    
    // MARK: Container view size changes
    
    override func preferredContentSizeDidChange(forChildContentContainer container: UIContentContainer) {
        let height = container.preferredContentSize.height
        let vc     = container as? UIViewController
        let margin: CGFloat // Account for anything else on the view (header label etc.).
        let isTv = UIDevice.current.userInterfaceIdiom == .tv
        
        if vc == relatedCollectionViewController {
            margin = height == 0 ? 0 : isTv ? 90 : 90 // If 0 height is passed in for the collection view, the container view is to be completely hidden.
            relatedContainerViewHeightConstraint.constant = height + margin
        } else if vc == peopleCollectionViewController {
            margin = height == 0 ? 0 : isTv ? 90 : 70 // If 0 height is passed in for the collection view, the container view is to be completely hidden.
            peopleContainerViewHeightConstraint.constant = height + margin
        } else if vc == episodesCollectionViewController {
             margin = height == 0 ? 0 : isTv ? 0 : 90 // If 0 height is passed in for the collection view, the container view is to be completely hidden.
            episodesContainerViewHeightConstraint.constant = height + margin
        } else if vc == informationDescriptionCollectionViewController {
            informationContainerViewHeightConstraint.constant = height
        } else if vc == accessibilityDescriptionCollectionViewController {
            accessibilityContainerViewHeightConstraint.constant = height
        }
    }
    
    // MARK: - Presentation
    
    dynamic func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        if presented is PreloadTorrentViewController {
            return PreloadTorrentViewControllerAnimatedTransitioning(isPresenting: true)
        }
        return nil
        
    }
    
    dynamic func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        if dismissed is PreloadTorrentViewController {
            return PreloadTorrentViewControllerAnimatedTransitioning(isPresenting: false)
        }
        return nil
    }
}
