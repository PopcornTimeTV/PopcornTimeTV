

import UIKit
import PopcornKit
import FloatRatingView
import PopcornTorrent
import AVKit
import XCDYouTubeKit

#if os(iOS)
    typealias ExpandableTextView = UIExpandableTextView
    typealias Button = UIButton
#elseif os(tvOS)
    typealias ExpandableTextView = TVExpandableTextView
    typealias Button = TVButton
#endif

class ItemViewController: UIViewController, PTTorrentDownloadManagerListener {
    
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var subtitleLabel: UILabel!
    @IBOutlet var infoLabel: UILabel!
    
    @IBOutlet var summaryTextView: ExpandableTextView!
    @IBOutlet var ratingView: FloatRatingView!
    
    @IBOutlet var trailerButton: Button!
    @IBOutlet var downloadButton: DownloadButton!
    @IBOutlet var playButton: Button!
    
    // iOS Exclusive
    
    @IBOutlet var imageView: UIImageView?
    @IBOutlet var genreLabel: UILabel?
    
    @IBOutlet var compactConstraints: [NSLayoutConstraint] = []
    @IBOutlet var regularConstraints: [NSLayoutConstraint] = []
    
    // tvOS Exclusive
    
    @IBOutlet var seasonsButton: Button?
    @IBOutlet var watchlistButton: Button?
    @IBOutlet var watchedButton: Button?
    
    @IBOutlet var peopleTextView: UITextView?
    
    var environmentsToFocus: [UIFocusEnvironment] = []
    
    override var preferredFocusEnvironments: [UIFocusEnvironment] {
        return environmentsToFocus.isEmpty ? super.preferredFocusEnvironments : environmentsToFocus
    }
    
    var media: Media!
    
    var watchedButtonImage: UIImage? {
        return media.isWatched ? UIImage(named: "Watched On") : UIImage(named: "Watched Off")
    }
    
    #if os(tvOS)
    
        var isDark = true {
            didSet {
                guard oldValue != isDark else { return }
    
                summaryTextView.isDark = isDark
                view.recursiveSubviews.compactMap({$0 as? TVButton}).forEach {
                    $0.isDark = self.isDark
                }
                let colorPallete: ColorPallete = isDark ? .light : .dark
                ratingView.tintColor = colorPallete.primary
                ratingView.type = .floatRatings
                titleLabel.textColor = colorPallete.primary
                subtitleLabel.textColor = colorPallete.primary
                infoLabel.textColor = colorPallete.primary
    
                reloadData()
            }
        }
    
    #endif
    
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
            let episode = show.latestUnwatchedEpisode() ?? show.episodes.filter({$0.season == show.seasonNumbers.first}).sorted(by: {$0.episode < $1.episode}).first
            media = episode ?? show
            
        }
        AppDelegate.shared.chooseQuality(sender, media: media) { torrent in
            AppDelegate.shared.play(media, torrent: torrent)
        }
    }
    
    @IBAction func playTrailer() {
        guard let id = (media as? Movie)?.trailerCode else { return }
        
        let playerController = AVPlayerViewController()
        
        playerController.transitioningDelegate = self as? UIViewControllerTransitioningDelegate// tvOS only
        
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
                if let index = qualities.firstIndex(of: quality) {
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
                let title = self.makeMetadataItem(AVMetadataIdentifier.commonIdentifierArtwork.rawValue, value: self.media.title)
                let summary = self.makeMetadataItem(AVMetadataIdentifier.commonIdentifierDescription.rawValue, value: self.media.summary)
                
                player.currentItem?.externalMetadata = [title, summary]
                
                if let string = self.media.mediumCoverImage,
                    let url = URL(string: string),
                    let data = try? Data(contentsOf: url) {
                    let image = self.makeMetadataItem(AVMetadataIdentifier.commonIdentifierArtwork.rawValue, value: data as NSData)
                    player.currentItem?.externalMetadata.append(image)
                }
                
            #endif
            
            playerController.player = player
            player.play()
            
            
            NotificationCenter.default.addObserver(self, selector: #selector(self.playerDidFinishPlaying), name: .AVPlayerItemDidPlayToEndTime, object: nil)
        }
    }
    
    @objc func playerDidFinishPlaying() {
        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: nil)
        dismiss(animated: true)
    }
    
    @objc func stopDownload(_ sender: DownloadButton) {
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
        downloadButton.downloadState = DownloadButton.buttonState(downloadStatus)
    }
    
    func downloadDidFail(_ download: PTTorrentDownload, withError error: Error) {
        guard download == media.associatedDownload else { return }
        AppDelegate.shared.download(download, failedWith: error)
    }
    
    deinit {
        PTTorrentDownloadManager.shared().remove(self)
    }
    
    private func makeMetadataItem(_ identifier: String,
                                  value: Any) -> AVMetadataItem {
        let item = AVMutableMetadataItem()
        item.identifier = AVMetadataIdentifier(rawValue: identifier)
        item.value = value as? NSCopying & NSObjectProtocol
        item.extendedLanguageTag = "und"
        return item.copy() as! AVMetadataItem
    }
}
