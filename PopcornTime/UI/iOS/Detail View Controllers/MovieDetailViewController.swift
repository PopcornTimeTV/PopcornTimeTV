

import Foundation
import UIKit
import XCDYouTubeKit
import AlamofireImage
import FloatRatingView
import PopcornTorrent
import PopcornKit

class MovieDetailViewController: UIViewController, UIViewControllerTransitioningDelegate, UIPopoverPresentationControllerDelegate, PCTPlayerViewControllerDelegate, UIGestureRecognizerDelegate {

    @IBOutlet var qualityButton: UIButton!
    @IBOutlet var subtitlesButton: UIButton!
    @IBOutlet var playButton: BorderButton!
    @IBOutlet var watchedButton: UIBarButtonItem!
    @IBOutlet var trailerButton: UIButton!
    @IBOutlet var castButton: CastIconBarButtonItem!

    @IBOutlet var scrollView: UIScrollView!
    @IBOutlet var collectionView: UICollectionView!
    
    @IBOutlet var backgroundImageView: UIImageView!
    
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var infoLabel: UILabel!
    
    @IBOutlet var ratingView: FloatRatingView!
    @IBOutlet var summaryView: ExpandableTextView!
    @IBOutlet var torrentHealthView: CircularView!
    @IBOutlet var blurView: UIVisualEffectView!
    @IBOutlet var gradientView: GradientView!
    
    @IBOutlet var regularConstraints: [NSLayoutConstraint]!
    @IBOutlet var compactConstraints: [NSLayoutConstraint]!
    
    var currentItem: Movie!
    var classContext = 0
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.isBackgroundHidden = true
        view.addObserver(self, forKeyPath: "frame", options: .new, context: &classContext)
        
        if transitionCoordinator?.viewController(forKey: .from) is LoadingViewController {
            transitionCoordinator?.animate(alongsideTransition: { (context) in
                guard let tabBarFrame = self.tabBarController?.tabBar.frame else { return }
                
                let tabBarOffsetY = -tabBarFrame.size.height
                self.tabBarController?.tabBar.frame = tabBarFrame.offsetBy(dx: 0, dy: tabBarOffsetY)
                
                self.gradientView.alpha = 1.0
                
                self.view.layoutIfNeeded()
            }, completion: nil)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.isBackgroundHidden = false
        view.removeObserver(self, forKeyPath: "frame")
        
        if transitionCoordinator?.viewController(forKey: .to) is LoadingViewController {
            transitionCoordinator?.animate(alongsideTransition: { (context) in
                guard let tabBarFrame = self.tabBarController?.tabBar.frame, let navigationBarFrame = self.navigationController?.navigationBar.frame else { return }
                
                let tabBarOffsetY = tabBarFrame.size.height
                let navigationOffsetY = -(navigationBarFrame.size.height + self.statusBarHeight)
                
                self.tabBarController?.tabBar.frame = tabBarFrame.offsetBy(dx: 0, dy: tabBarOffsetY)
                self.navigationController?.navigationBar.frame = navigationBarFrame.offsetBy(dx: 0, dy: navigationOffsetY)
                
                self.gradientView.alpha = 0.0
                
                self.view.layoutIfNeeded()
            }, completion: nil)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = currentItem.title
        watchedButton.image = watchedButtonImage
        (castButton.customView as! CastIconButton).addTarget(self, action: #selector(castButtonTapped), for: .touchUpInside)
        
        let inset = tabBarController?.tabBar.frame.height ?? 0.0
        scrollView.contentInset.bottom = inset
        scrollView.scrollIndicatorInsets.bottom = inset
        
        
        titleLabel.text = currentItem.title
        summaryView.text = currentItem.summary
        ratingView.rating = Float(currentItem.rating)
        infoLabel.text = "\(currentItem.year) ● \(currentItem.runtime) min ● \(currentItem.genres.first!.capitalized)"
        trailerButton.isEnabled = currentItem.trailer != nil
        
        qualityButton.isUserInteractionEnabled = currentItem.torrents.count > 1
        
        currentItem.currentTorrent = currentItem.torrents.first(where: {$0.quality == UserDefaults.standard.string(forKey: "preferredQuality")}) ?? currentItem.torrents.first
        if let torrent = currentItem.currentTorrent, let quality = torrent.quality {
            qualityButton.setTitle("\(quality + (currentItem.torrents.count > 1 ? " ▾" : ""))", for: .normal)
        } else {
            qualityButton.setTitle("No torrents available.", for: .normal)
        }
        torrentHealthView.backgroundColor = currentItem.currentTorrent?.health.color
        playButton.isEnabled = currentItem.currentTorrent?.url != nil
        
        SubtitlesManager.shared.search(imdbId: currentItem.id, completion: { [weak self] (subtitles, error) in
            guard let `self` = self else { return }
            guard error == nil else { self.subtitlesButton.setTitle("Error loading subtitles", for: .normal); return }
            self.currentItem.subtitles = subtitles
            guard !subtitles.isEmpty else { self.subtitlesButton.setTitle("No Subtitles Available", for: .normal); return }
            
            self.subtitlesButton.setTitle("None ▾", for: .normal)
            self.subtitlesButton.isUserInteractionEnabled = true
            
            if let preferredSubtitle = SubtitleSettings().language {
                let languages = subtitles.flatMap({$0.language})
                let index = languages.index{$0 == languages.first(where: {$0 == preferredSubtitle})}
                let subtitle = self.currentItem.subtitles![index!]
                self.currentItem.currentSubtitle = subtitle
                self.subtitlesButton.setTitle(subtitle.language + " ▾", for: .normal)
            }
        })
        
        TraktManager.shared.getRelated(currentItem) { [weak self] (movies, _) in
            guard let `self` = self else { return }
            self.currentItem.related = movies
            self.collectionView.reloadData()
        }
        TraktManager.shared.getPeople(forMediaOfType: .movies, id: currentItem.id) { [weak self] (actors, crew, _) in
            guard let `self` = self else { return }
            self.currentItem.crew = crew
            self.currentItem.actors = actors
            self.collectionView.reloadData()
        }
    }
    
    var watchedButtonImage: UIImage {
        return WatchedlistManager.movie.isAdded(currentItem.id) ? UIImage(named: "WatchedOn")! : UIImage(named: "WatchedOff")!
    }
    
    @IBAction func toggleWatched() {
        WatchedlistManager.movie.toggle(currentItem.id)
        watchedButton.image = watchedButtonImage
    }
    
    @IBAction func changeQuality(_ sender: UIButton) {
        let quality = UIAlertController(title: "Select Quality", message: nil, preferredStyle: .actionSheet)
        for torrent in currentItem.torrents {
            quality.addAction(UIAlertAction(title: "\(torrent.quality!) \(torrent.size!)", style: .default, handler: { [weak self] action in
                self?.currentItem.currentTorrent = torrent
                self?.playButton.isEnabled = self?.currentItem.currentTorrent?.url != nil
                self?.qualityButton.setTitle("\(torrent.quality!) ▾", for: .normal)
                self?.torrentHealthView.backgroundColor = torrent.health.color
            }))
        }
        quality.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        quality.popoverPresentationController?.sourceView = sender
        present(quality, animated: true, completion: nil)
    }
    
    @IBAction func changeSubtitle(_ sender: UIButton) {
        let controller = UIAlertController(title: "Select Subtitle", message: nil, preferredStyle: .actionSheet)
        guard let subtitles = currentItem.subtitles else { return }
        
        let handler: (UIAlertAction) -> Void = { (action) in
            guard let index = subtitles.index(where: {$0.language == action.title }),
                let currentSubtitle = subtitles.first(where: {$0 == subtitles[index]}) else { return }
            self.currentItem.currentSubtitle = currentSubtitle
            self.subtitlesButton.setTitle(currentSubtitle.language + " ▾", for: .normal)
        }
        controller.addAction(UIAlertAction(title: "None", style: .default, handler: { (action) in
            self.currentItem.currentSubtitle = nil
            self.subtitlesButton.setTitle("None ▾", for: .normal)
        }))
        
        for subtitle in subtitles.flatMap({$0.language}) {
            controller.addAction(UIAlertAction(title: subtitle, style: .default, handler: handler))
        }
        
        controller.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        let preferredLanguage = SubtitleSettings().language
        controller.preferredAction = controller.actions.first(where: {$0.title == preferredLanguage})
        controller.popoverPresentationController?.sourceView = sender
        present(controller, animated: true, completion: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showCasts", let vc = (segue.destination as? UINavigationController)?.viewControllers.first as? StreamToDevicesTableViewController {
            segue.destination.popoverPresentationController?.delegate = self
            vc.onlyShowCastDevices = true
        } else if segue.identifier == "showRelated",
            let vc = segue.destination as? MovieDetailViewController,
            let cell = sender as? CoverCollectionViewCell,
            let index = collectionView.indexPath(for: cell)?.row {
            vc.currentItem = currentItem.related[index]
        } else if segue.identifier == "showActor",
            let vc = segue.destination as? ActorDetailCollectionViewController,
            let cell = sender as? UICollectionViewCell,
            let index = collectionView.indexPath(for: cell)?.row {
            vc.currentItem = currentItem.actors[index]
        }
    }
    
    func castButtonTapped() {
        performSegue(withIdentifier: "showCasts", sender: castButton)
    }
    
    func updateCastStatus() {
        (castButton.customView as! CastIconButton).status = GCKCastContext.sharedInstance().castState
    }
    
    func presentationController(_ controller: UIPresentationController, viewControllerForAdaptivePresentationStyle style: UIModalPresentationStyle) -> UIViewController? {
        (controller.presentedViewController as! UINavigationController).topViewController?.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(cancelButtonPressed))
        return controller.presentedViewController
        
    }
    
    func cancelButtonPressed() {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func playTrailer() {
        let vc = XCDYouTubeVideoPlayerViewController(videoIdentifier: currentItem.trailerCode)
        present(vc, animated: true, completion: nil)
    }
    
    @IBAction func playMovie() {
        if UserDefaults.standard.bool(forKey: "streamOnCellular") || (UIApplication.shared.delegate! as! AppDelegate).reachability!.isReachableViaWiFi() {
            
            let currentProgress = WatchedlistManager.movie.currentProgress(currentItem.id)
            
            let loadingViewController = storyboard?.instantiateViewController(withIdentifier: "LoadingViewController") as! LoadingViewController
            loadingViewController.transitioningDelegate = self
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
                self?.playMovie()
            }))
            errorAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            self.present(errorAlert, animated: true, completion: nil)
        }
    }
    
    func presentCastPlayer(_ media: Media, videoFilePath: URL, startPosition: TimeInterval) {
        // TODO: Implement
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
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
