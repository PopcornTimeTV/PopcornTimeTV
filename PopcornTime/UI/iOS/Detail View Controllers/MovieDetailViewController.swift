

import Foundation
import UIKit
import XCDYouTubeKit
import AlamofireImage
import FloatRatingView
import PopcornTorrent
import PopcornKit

class MovieDetailViewController: UIViewController, PCTPlayerViewControllerDelegate, CollectionViewControllerDelegate, UIScrollViewDelegate {

    @IBOutlet var watchedButton: UIBarButtonItem!
    @IBOutlet var castButton: CastIconBarButtonItem!

    @IBOutlet var scrollView: UIScrollView!
    @IBOutlet var backgroundImageView: UIImageView!
    
    var relatedCollectionViewController: CollectionViewController!
    var castCollectionViewController: CollectionViewController!
    var informationCollectionViewController: DescriptionCollectionViewController!
    var accessibilityCollectionViewController: DescriptionCollectionViewController!
    
    var currentItem: Movie!
    var headerHeight: CGFloat = 315
    
    
    @IBOutlet var relatedViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet var castViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet var seasonsViewHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet var relatedCollectionViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet var castCollectionViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet var informationCollectionViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet var accessibilityCollectionViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet var seasonsCollectionViewHeightConstraint: NSLayoutConstraint!
    
    
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
        watchedButton.image = watchedButtonImage
        
        scrollView.contentInset.bottom = tabBarController?.tabBar.frame.height ?? 0
        
        if let image = currentItem.largeBackgroundImage, let url = URL(string: image) {
            backgroundImageView.af_setImage(withURL: url)
        }
        
        TMDBManager.shared.getLogo(forMediaOfType: .movies, id: currentItem.id) { [weak self] (image, error) in
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
        
        TraktManager.shared.getRelated(currentItem) { [weak self] (related, error) in
            guard let `self` = self else { return }
            
            self.currentItem.related = related

            self.relatedCollectionViewController.dataSource = related
            self.relatedCollectionViewController.collectionView?.reloadData()
        }
        
        TraktManager.shared.getPeople(forMediaOfType: .movies, id: currentItem.id) { [weak self] (actors, crew, error) in
            guard let `self` = self else { return }
            
            self.currentItem.actors = actors
            self.currentItem.crew = crew
            
            self.castCollectionViewController.dataSource = actors
            self.castCollectionViewController.dataSource += crew as [AnyHashable]
            
            self.castCollectionViewController.collectionView?.reloadData()
        }
        
        scrollView.contentInset.top = headerHeight
    }
    
    var watchedButtonImage: UIImage {
        return WatchedlistManager<Movie>.movie.isAdded(currentItem.id) ? UIImage(named: "Watched On")! : UIImage(named: "Watched Off")!
    }
    
    @IBAction func toggleWatched() {
        WatchedlistManager<Movie>.movie.toggle(currentItem.id)
        watchedButton.image = watchedButtonImage
    }
    
    func updateCastStatus() {
        (castButton.customView as! CastIconButton).status = GCKCastContext.sharedInstance().castState
    }
    
    @IBAction func playTrailer() {
        let vc = XCDYouTubeVideoPlayerViewController(videoIdentifier: currentItem.trailerCode)
        present(vc, animated: true, completion: nil)
    }
    
    @IBAction func playMovie() {
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
                self?.playMovie()
            }))
            errorAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            self.present(errorAlert, animated: true, completion: nil)
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
        if segue.identifier == "embedInfo",
            let vc = segue.destination as? InfoViewController {
            
            let info = NSMutableAttributedString(string: "\(currentItem.year)\t")
            
            attributedString(from: currentItem.certification, "HD", "CC").forEach({info.append($0)})
            
            vc.info = (title: currentItem.title, length: formattedRuntime, genre: currentItem.genres.first?.capitalized ?? "", info: info, rating: currentItem.rating, summary: currentItem.summary, image: currentItem.mediumCoverImage)
            
            vc.view.translatesAutoresizingMaskIntoConstraints = false
        } else if let vc = segue.destination as? DescriptionCollectionViewController {
            vc.delegate = self
            
            if segue.identifier == "embedInformation" {
                vc.headerTitle = "Information"
                
                vc.dataSourceTuple = [("Genre", currentItem.genres.first?.capitalized ?? "Unknown"), ("Released", currentItem.year), ("Run Time", formattedRuntime), ("Rating", currentItem.certification)]
                
                informationCollectionViewController = vc
            } else if segue.identifier == "embedAccessibility" {
                vc.headerTitle = "Accessibility"
                
                let key = attributedString(from: "SDH").first!
                let value = "Subtitles for the deaf and Hard of Hearing (SDH) refer to subtitles in the original lanuage with the addition of relevant non-dialog information."
                
                vc.dataSourceTuple = [(key, value)]
                
                accessibilityCollectionViewController = vc
            }
        } else if let vc = segue.destination as? CollectionViewController {
            vc.delegate = self
            
            if segue.identifier == "embedRelated" {
                relatedCollectionViewController = vc
            } else if segue.identifier == "embedCast" {
                castCollectionViewController = vc
                castCollectionViewController.minItemSize.height = 230
            }
            
            let layout = vc.collectionView?.collectionViewLayout as? UICollectionViewFlowLayout
            layout?.scrollDirection = .horizontal
            layout?.minimumLineSpacing = 30
            vc.collectionView?.showsHorizontalScrollIndicator = false
            vc.collectionView?.contentInset.left = 48
            vc.collectionView?.contentInset.right = 48
        }
    }
    
    func attributedString(from images: String...) -> [NSAttributedString] {
        return images.flatMap({
            let attachment = NSTextAttachment()
            attachment.image = UIImage(named: $0)?.colored(.white)
            
            let string = NSMutableAttributedString(attributedString: NSAttributedString(attachment: attachment))
            string.append(NSAttributedString(string: "\t"))
            
            return string
        })
    }
    
    func secondsToHoursMinutesSeconds(_ seconds: Int) -> (Int, Int, Int) {
        return (seconds / 3600, (seconds % 3600) / 60, (seconds % 3600) % 60)
    }
    
    var formattedRuntime: String {
        if let runtime = Int(currentItem.runtime) {
            let (hours, minutes, _) = secondsToHoursMinutesSeconds(runtime * 60)
            
            let formatted = "\(hours) h"
            
            return minutes > 0 ? formatted + " \(minutes) min" : formatted
        }
        return ""
    }
    
    func collectionViewController(_ collectionViewController: CollectionViewController, preferredSizeForLayout size: CGSize) {
        if collectionViewController == relatedCollectionViewController {
            relatedCollectionViewHeightConstraint.constant = size.height
            relatedViewHeightConstraint.priority = size.height == 0 ? 999 : 1
        } else if collectionViewController == castCollectionViewController {
            castCollectionViewHeightConstraint.constant = size.height
            castViewHeightConstraint.priority = size.height == 0 ? 999 : 1
        } else if collectionViewController == informationCollectionViewController {
            informationCollectionViewHeightConstraint.constant = size.height
        } else if collectionViewController == accessibilityCollectionViewController {
            accessibilityCollectionViewHeightConstraint.constant = size.height
        }
    }
}
