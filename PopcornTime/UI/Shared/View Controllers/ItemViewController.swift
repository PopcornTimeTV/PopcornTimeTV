

import UIKit
import PopcornKit
import FloatRatingView
import PopcornTorrent
import AVKit
import XCDYouTubeKit

class ItemViewController: UIViewController, PTTorrentDownloadManagerListener {
    
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var subtitleLabel: UILabel!
    @IBOutlet var infoLabel: UILabel!
    
    
    @IBOutlet var summaryTextView: TVExpandableTextView!
    @IBOutlet var ratingView: FloatRatingView!
    
    @IBOutlet var trailerButton: BorderButton!
    @IBOutlet var downloadButton: DownloadButton!
    @IBOutlet var playButton: CircularButton!
    
    // iOS Exclusive
    
    @IBOutlet var imageView: UIImageView?
    @IBOutlet var genreLabel: UILabel?
    
    @IBOutlet var compactConstraints: [NSLayoutConstraint] = []
    @IBOutlet var regularConstraints: [NSLayoutConstraint] = []
    
    // tvOS Exclusive
    
    @IBOutlet var seasonsButton: TVButton?
    @IBOutlet var watchlistButton: TVButton?
    @IBOutlet var watchedButton: TVButton?
    
    @IBOutlet var peopleTextView: UITextView?
    
    var environmentsToFocus: [UIFocusEnvironment] = []
    
    override var preferredFocusEnvironments: [UIFocusEnvironment] {
        return environmentsToFocus.isEmpty ? super.preferredFocusEnvironments : environmentsToFocus
    }
    
    var media: Media!
    
    var watchedButtonImage: UIImage? {
        return media.isWatched ? UIImage(named: "Watched On") : UIImage(named: "Watched Off")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let download = media.associatedDownload {
            downloadStatusDidChange(download.downloadStatus, for: download)
        } else {
            downloadButton.downloadState = .normal
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        parent?.prepare(for: segue, sender: sender)
    }
    
    @IBAction func play(_ sender: UIView) {
        let media: Media
        if let movie = self.media as? Movie {
            media = movie
        } else {
            let show = self.media as! Show
            let episode = show.latestUnwatchedEpisode() ?? show.episodes.filter({$0.season == show.seasonNumbers.first}).sorted(by: {$0.0.episode < $0.1.episode}).first
            media = episode ?? show
            
        }
        AppDelegate.shared.chooseQuality(sender, media: media) { torrent in
            AppDelegate.shared.play(media, torrent: torrent)
        }
    }
    
    @IBAction func playTrailer() {
        guard let id = (media as? Movie)?.trailerCode else { return }
        
        let playerController = AVPlayerViewController()
        
        if let `self` = self as? UIViewControllerTransitioningDelegate // tvOS only
        {
            playerController.transitioningDelegate = self
        }
        
        present(playerController, animated: true)
        
        XCDYouTubeClient.default().getVideoWithIdentifier(id) { (video, error) in
            guard
                let streamUrls = video?.streamURLs,
                let qualities = Array(streamUrls.keys) as? [UInt]
                else {
                    return
            }
            
            let preferredVideoQualities = [XCDYouTubeVideoQuality.HD720.rawValue, XCDYouTubeVideoQuality.medium360.rawValue, XCDYouTubeVideoQuality.small240.rawValue]
            var videoUrl: URL?
            
            for quality in preferredVideoQualities {
                if let index = qualities.index(of: quality) {
                    videoUrl = Array(streamUrls.values)[index]
                    break
                }
            }
            
            guard let url = videoUrl else {
                self.dismiss(animated: true)
                
                let vc = UIAlertController(title: "Error".localized, message: "Error fetching valid trailer URL from YouTube.".localized, preferredStyle: .alert)
                
                vc.addAction(UIAlertAction(title: "OK".localized, style: .cancel, handler: nil))
                
                self.present(vc, animated: true)
                
                return
            }
            
            let player = AVPlayer(url: url)
            
            #if os(tvOS)
            
                let title = AVMetadataItem(key: AVMetadataCommonKeyTitle as NSString, value: self.media.title as NSString)
                let summary = AVMetadataItem(key: AVMetadataCommonKeyDescription as NSString, value: self.media.summary as NSString)
                
                player.currentItem?.externalMetadata = [title, summary]
                
                if let string = self.media.mediumCoverImage,
                    let url = URL(string: string),
                    let data = try? Data(contentsOf: url) {
                    let image = AVMetadataItem(key: AVMetadataCommonKeyArtwork as NSString, value: data as NSData)
                    player.currentItem?.externalMetadata.append(image)
                }
                
            #endif
            
            playerController.player = player
            player.play()
            
            
            NotificationCenter.default.addObserver(self, selector: #selector(self.playerDidFinishPlaying), name: .AVPlayerItemDidPlayToEndTime, object: nil)
        }
    }
    
    func playerDidFinishPlaying() {
        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: nil)
        dismiss(animated: true)
    }
    
    func stopDownload(_ sender: DownloadButton) {
        guard let download = media.associatedDownload else { return }
        AppDelegate.shared.downloadButton(sender, wantsToStop: download)
    }
    
    @IBAction func download(_ sender: DownloadButton) {
        if sender.downloadState == .normal {
            AppDelegate.shared.chooseQuality(sender, media: media) { [unowned self] (torrent) in
                PTTorrentDownloadManager.shared().startDownloading(fromFileOrMagnetLink: torrent.url, mediaMetadata: self.media.mediaItemDictionary)
                
                sender.downloadState = .pending
            }
        } else if let download = media.associatedDownload {
            AppDelegate.shared.downloadButton(sender, wasPressedWith: download)
        }
    }
    
    
    // MARK: - PTTorrentDownloadManagerListener
    
    func torrentStatusDidChange(_ torrentStatus: PTTorrentStatus, for download: PTTorrentDownload) {
        guard download == media.associatedDownload else { return }
        downloadButton.progress = torrentStatus.totalProgress
    }
    
    func downloadStatusDidChange(_ downloadStatus: PTTorrentDownloadStatus, for download: PTTorrentDownload) {
        guard download == media.associatedDownload else { return }
        downloadButton.downloadState = DownloadButton.State(downloadStatus)
    }
    
    func downloadDidFail(_ download: PTTorrentDownload, withError error: Error) {
        guard download == media.associatedDownload else { return }
        AppDelegate.shared.download(download, failedWith: error)
    }
    
    deinit {
        PTTorrentDownloadManager.shared().remove(self)
    }
}
