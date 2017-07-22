

import UIKit
import AlamofireImage
import struct PopcornKit.Episode
import PopcornTorrent

class EpisodeDetailViewController: UIViewController, UIScrollViewDelegate, UIGestureRecognizerDelegate, PTTorrentDownloadManagerListener {
    
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var subtitleLabel: UILabel!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var infoLabel: UILabel!
    @IBOutlet var summaryTextView: UIExpandableTextView!
    @IBOutlet var scrollView: UIScrollView!
    
    @IBOutlet var downloadButton: DownloadButton!
    @IBOutlet var playButton: CircularButton!
    
    var episode: Episode!
    var interactor: EpisodeDetailPercentDrivenInteractiveTransition?
    
    @IBOutlet var dismissPanGestureRecognizer: UIPanGestureRecognizer!
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        preferredContentSize = scrollView.contentSize
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let download = episode.associatedDownload {
            downloadStatusDidChange(download.downloadStatus, for: download)
        } else {
            downloadButton.downloadState = .normal
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        PTTorrentDownloadManager.shared().add(self)
        downloadButton.addTarget(self, action: #selector(stopDownload(_:)), for: .applicationReserved)
        
        subtitleLabel.text = "Season".localized.localizedUppercase + " \(episode.season) • " + "Episode".localized.localizedUppercase + " \(episode.episode)"
        titleLabel.text = episode.title
        summaryTextView.text = episode.summary
        
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .short
        formatter.allowedUnits = [.hour, .minute]
        
        let info = NSMutableAttributedString(string: "\(DateFormatter.localizedString(from: episode.firstAirDate, dateStyle: .medium, timeStyle: .none))\t\(formatter.string(from: TimeInterval(episode.show?.runtime ?? 0) * 60) ?? "0 min")")
        attributedString(with: 10, between: "HD", "CC").forEach({info.append($0)})
        infoLabel.attributedText = info
        
        
        if let image = episode.largeBackgroundImage,
            let url = URL(string: image) {
            imageView.af_setImage(withURL: url, placeholderImage: UIImage(named: "Episode Placeholder"), imageTransition: .crossDissolve(.default))
        }
        
        scrollView.setNeedsLayout()
        scrollView.layoutIfNeeded()
        preferredContentSize = scrollView.contentSize
    }
    
    
    @IBAction func handleDismissPan(_ sender: UIPanGestureRecognizer) {
        let percentThreshold: CGFloat = 0.12
        let superview = sender.view!.superview!
        let translation = sender.translation(in: superview)
        let progress = translation.y/superview.bounds.height/3.0
        
        guard let interactor = interactor else { return }
        
        switch sender.state {
        case .began:
            interactor.hasStarted = true
            dismiss(animated: true)
            scrollView.bounces = false
        case .changed:
            interactor.shouldFinish = progress > percentThreshold
            interactor.update(progress)
        case .cancelled:
            interactor.hasStarted = false
            interactor.cancel()
            scrollView.bounces = true
        case .ended:
            interactor.hasStarted = false
            interactor.shouldFinish ? interactor.finish() : interactor.cancel()
            scrollView.bounces = true
        default:
            break
        }
    }
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard gestureRecognizer == dismissPanGestureRecognizer else { return true }
        let isRegular = traitCollection.horizontalSizeClass == .regular && traitCollection.verticalSizeClass == .regular
        return scrollView.contentOffset.y == 0 && !isRegular ? true : false
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    @IBAction func play(_ sender: UIView) {
        AppDelegate.shared.chooseQuality(sender, media: episode) { [unowned self] (torrent) in
            self.dismiss(animated: false)
            AppDelegate.shared.play(self.episode, torrent: torrent)
        }
    }
    
    func stopDownload(_ sender: DownloadButton) {
        guard let download = episode.associatedDownload else { return }
        AppDelegate.shared.downloadButton(sender, wantsToStop: download)
    }
    
    @IBAction func download(_ sender: DownloadButton) {
        if sender.downloadState == .normal {
            AppDelegate.shared.chooseQuality(sender, media: episode) { [unowned self] (torrent) in
                PTTorrentDownloadManager.shared().startDownloading(fromFileOrMagnetLink: torrent.url, mediaMetadata: self.episode.mediaItemDictionary)
                
                sender.downloadState = .pending
            }
        } else if let download = episode.associatedDownload {
            AppDelegate.shared.downloadButton(sender, wasPressedWith: download)
        }
    }
    
    // MARK: - PTTorrentDownloadManagerListener
    
    func torrentStatusDidChange(_ torrentStatus: PTTorrentStatus, for download: PTTorrentDownload) {
        guard download == episode.associatedDownload else { return }
        downloadButton.progress = torrentStatus.totalProgress
    }
    
    func downloadStatusDidChange(_ downloadStatus: PTTorrentDownloadStatus, for download: PTTorrentDownload) {
        guard download == episode.associatedDownload else { return }
        downloadButton.downloadState = DownloadButton.State(downloadStatus)
    }
    
    func downloadDidFail(_ download: PTTorrentDownload, withError error: Error) {
        guard download == episode.associatedDownload else { return }
        AppDelegate.shared.download(download, failedWith: error)
    }
    
    deinit {
        PTTorrentDownloadManager.shared().remove(self)
    }
}
