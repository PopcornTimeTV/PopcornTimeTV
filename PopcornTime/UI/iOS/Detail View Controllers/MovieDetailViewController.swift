

import Foundation
import UIKit
import XCDYouTubeKit
import AlamofireImage
import FloatRatingView
import PopcornTorrent
import PopcornKit

class MovieDetailViewController: UIViewController, PCTPlayerViewControllerDelegate {

    @IBOutlet var watchedButton: UIBarButtonItem!
    @IBOutlet var castButton: CastIconBarButtonItem!

    @IBOutlet var scrollView: UIScrollView!
    @IBOutlet var backgroundImageView: UIImageView!
    
    var currentItem: Movie!
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.isBackgroundHidden = true
        NotificationCenter.default.addObserver(self, selector: #selector(updateCastStatus), name: .gckCastStateDidChange, object: nil)
        updateCastStatus()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.isBackgroundHidden = false
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = currentItem.title
        watchedButton.image = watchedButtonImage
        (castButton.customView as! CastIconButton).addTarget(self, action: #selector(castButtonTapped), for: .touchUpInside)
        
        if let image = currentItem.largeBackgroundImage, let url = URL(string: image) {
            backgroundImageView.af_setImage(withURL: url)
        }
        
        TMDBManager.shared.getLogo(forMediaOfType: .movies, id: currentItem.id) { [weak self] (image, error) in
            if let image = image, let url = URL(string: image) {
                let imageView = UIImageView(frame: CGRect(origin: .zero, size: CGSize(width: .max, height: 40)))
                imageView.clipsToBounds = true
                imageView.contentMode = .scaleAspectFit
                imageView.af_setImage(withURL: url) { [weak self] response in
                    guard response.result.isSuccess else { return }
                    self?.navigationItem.titleView = imageView
                }
            }
        }
        
        scrollView.contentInset.top = 315
    }
    
    var watchedButtonImage: UIImage {
        return WatchedlistManager<Movie>.movie.isAdded(currentItem.id) ? UIImage(named: "Watched On")! : UIImage(named: "Watched Off")!
    }
    
    @IBAction func toggleWatched() {
        WatchedlistManager<Movie>.movie.toggle(currentItem.id)
        watchedButton.image = watchedButtonImage
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
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "embedInfo",
            let vc = segue.destination as? InfoViewController {
            
            let info = NSMutableAttributedString(string: "\(formattedRuntime)\t\(currentItem.year)\t")
            
            attributedString(from: currentItem.certification, "HD", "CC").forEach({info.append($0)})
            
            vc.info = (title: currentItem.title, info: info, rating: currentItem.rating, summary: currentItem.summary, image: currentItem.mediumCoverImage)
        }
    }
    
    func attributedString(from images: String...) -> [NSAttributedString] {
        return images.flatMap({
            let attachment = NSTextAttachment()
            attachment.image = UIImage(named: $0)?.colored(.white)
            
            let string = NSMutableAttributedString(attributedString: NSAttributedString(attachment: attachment))
            string.append(NSAttributedString(string: "  "))
            
            return string
        })
    }
    
    func secondsToHoursMinutesSeconds(_ seconds: Int) -> (Int, Int, Int) {
        return (seconds / 3600, (seconds % 3600) / 60, (seconds % 3600) % 60)
    }
    
    var formattedRuntime: String {
        let (hours, minutes, _) = secondsToHoursMinutesSeconds(Int(currentItem.runtime)! * 60)
        return "\(hours) h \(minutes) min"
    }
}
