

import Foundation
import UIKit
import XCDYouTubeKit
import AlamofireImage
import FloatRatingView
import PopcornTorrent
import PopcornKit

class DetailViewController: UIViewController, PCTPlayerViewControllerDelegate, CollectionViewControllerDelegate, UIScrollViewDelegate {

    @IBOutlet var castButton: CastIconBarButtonItem!
    @IBOutlet var seasonsLabel: UILabel!

    @IBOutlet var scrollView: UIScrollView!
    @IBOutlet var infoStackView: UIStackView!
    @IBOutlet var backgroundImageView: UIImageView!
    
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
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.isBackgroundHidden = false
        NotificationCenter.default.removeObserver(self)
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
    
    @IBAction func play() {
        if UserDefaults.standard.bool(forKey: "streamOnCellular") || (UIApplication.shared.delegate as! AppDelegate).reachability!.isReachableViaWiFi() {
            
            let currentProgress = WatchedlistManager<Movie>.movie.currentProgress(currentItem.id)
            
            let loadingViewController = storyboard?.instantiateViewController(withIdentifier: "LoadingViewController") as! LoadingViewController
            loadingViewController.backgroundImage = backgroundImageView.image
            present(loadingViewController, animated: true, completion: nil)
            
            let error: (String) -> Void = { [weak self] (errorMessage) in
                let alertVc = UIAlertController(title: "Error", message: errorMessage, preferredStyle: .alert)
                alertVc.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                self?.present(alertVc, animated: true, completion: nil)
            }
            
            let finishedLoading: (LoadingViewController, UIViewController) -> Void = { [weak self] (loadingVc, playerVc) in
                loadingVc.dismiss(animated: false, completion: nil)
                self?.present(playerVc, animated: true, completion: nil)
            }
            
            if GCKCastContext.sharedInstance().castState == .connected {
                let playViewController = self.storyboard?.instantiateViewController(withIdentifier: "CastPlayerViewController") as! CastPlayerViewController
                currentItem.playOnChromecast(fromFileOrMagnetLink: currentItem.currentTorrent!.url, loadingViewController: loadingViewController, playViewController: playViewController, progress: currentProgress, errorBlock: error, finishedLoadingBlock: finishedLoading)
            } else {
                let playViewController = self.storyboard?.instantiateViewController(withIdentifier: "PCTPlayerViewController") as! PCTPlayerViewController
                playViewController.delegate = self
                currentItem.play(fromFileOrMagnetLink: currentItem.currentTorrent!.url, loadingViewController: loadingViewController, playViewController: playViewController, progress: currentProgress, errorBlock: error, finishedLoadingBlock: finishedLoading)
            }
        } else {
            let errorAlert = UIAlertController(title: "Cellular Data is turned off for streaming", message: nil, preferredStyle: .alert)
            errorAlert.addAction(UIAlertAction(title: "Turn On", style: .default, handler: { [weak self] _ in
                UserDefaults.standard.set(true, forKey: "streamOnCellular")
                self?.play()
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
        
        for constraint in compactConstraints {
            constraint.priority = isCompact ? 999 : 240
        }
        for constraint in regularConstraints {
            constraint.priority = isCompact ? 240 : 999
        }
    }
}
