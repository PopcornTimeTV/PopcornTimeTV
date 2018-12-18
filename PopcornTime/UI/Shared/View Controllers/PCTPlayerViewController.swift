

import UIKit
import MediaPlayer
import PopcornTorrent
import PopcornKit


protocol PCTPlayerViewControllerDelegate: class {
    func playNext(_ episode: Episode)
    
    #if os(iOS)
        func playerViewControllerPresentCastPlayer(_ playerViewController: PCTPlayerViewController)
    #endif
}

/// Optional functions
extension PCTPlayerViewControllerDelegate {
    func playNext(_ episode: Episode) {}
}

class PCTPlayerViewController: UIViewController, VLCMediaPlayerDelegate, UIGestureRecognizerDelegate, UpNextViewControllerDelegate, OptionsViewControllerDelegate {
    
    // MARK: - IBOutlets
    
    @IBOutlet var movieView: UIView!
    @IBOutlet var loadingActivityIndicatorView: UIView!
    @IBOutlet var progressBar: ProgressBar!
    
    @IBOutlet var overlayViews: [UIView] = []
    
    // tvOS exclusive
    @IBOutlet var dimmerView: UIView?
    @IBOutlet var infoHelperView: UIView?
    
    var lastTranslation: CGFloat = 0.0
    
    // iOS exclusive
    @IBOutlet var airPlayingView: UIView?
    @IBOutlet var screenshotImageView: UIImageView?
    @IBOutlet var upNextContainerView: UIView?
    
    @IBOutlet var playPauseButton: UIButton?
    @IBOutlet var subtitleSwitcherButton: UIButton?
    @IBOutlet var videoDimensionsButton: UIButton?
    @IBOutlet var volumeButton: UIButton?
    
    @IBOutlet var tapOnVideoRecognizer: UITapGestureRecognizer?
    @IBOutlet var doubleTapToZoomOnVideoRecognizer: UITapGestureRecognizer?
    
    @IBOutlet var regularConstraints: [NSLayoutConstraint] = []
    @IBOutlet var compactConstraints: [NSLayoutConstraint] = []
    @IBOutlet var showVolumeConstraint: NSLayoutConstraint?
    @IBOutlet var tooltipView: UIView?
    @IBOutlet var duringScrubbingConstraints: NSLayoutConstraint?
    @IBOutlet var finishedScrubbingConstraints: NSLayoutConstraint?
    @IBOutlet var subtitleSwitcherButtonWidthConstraint: NSLayoutConstraint?
    
    @IBOutlet var scrubbingSpeedLabel: UILabel?
    
    #if os(iOS)
        internal var previousVolumeValue = 0.0
        @IBOutlet var volumeSliderView: UIView?
    
        internal var volumeView: MPVolumeView = {
            let view = MPVolumeView(frame: CGRect(x: 0, y: 14, width: 118, height: 30))
            view.sizeToFit()
            view.showsRouteButton = false
            return view
        }()
    #endif
    
    
    
    // MARK: - Slider actions

    func positionSliderDidDrag() {
        let time = NSNumber(value: progressBar.scrubbingProgress * streamDuration)
        let remainingTime = NSNumber(value: time.floatValue - streamDuration)
        progressBar.remainingTimeLabel.text = VLCTime(number: remainingTime).stringValue
        progressBar.scrubbingTimeLabel.text = VLCTime(number: time).stringValue
        workItem?.cancel()
        workItem = DispatchWorkItem { [weak self] in
            if let image = self?.screenshotAtTime(time) {
                #if os(tvOS)
                    self?.progressBar.screenshot = image
                #elseif os(iOS)
                    self?.screenshotImageView?.image = image
                #endif
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25, execute: workItem!)
    }
    
    func positionSliderAction() {
        resetIdleTimer()
        mediaplayer.play()
        if mediaplayer.isSeekable {
            let time = NSNumber(value: progressBar.scrubbingProgress * streamDuration)
            mediaplayer.time = VLCTime(number: time)
        }
    }
    
    // MARK: - Button actions
    
    @IBAction func playandPause() {
        #if os(tvOS)
            // Make fake gesture to trick clickGesture: into recognising the touch.
            let gesture = SiriRemoteGestureRecognizer(target: nil, action: nil)
            gesture.isClick = true
            gesture.state = .ended
            clickGesture(gesture)
        #elseif os(iOS)
            if mediaplayer.isPlaying {
                mediaplayer.canPause ? mediaplayer.pause() : ()
            } else {
                mediaplayer.willPlay ? mediaplayer.play() : ()
            }
        #endif
    }
    
    @IBAction func fastForward() {
        mediaplayer.jumpForward(30)
    }
    
    @IBAction func rewind() {
        mediaplayer.jumpBackward(30)
    }
    
    @IBAction func fastForwardHeld(_ sender: UIGestureRecognizer) {
        switch sender.state {
        case .began:
            fallthrough
        case .changed:
            #if os(tvOS)
            progressBar.hint = .fastForward
            #endif
            guard mediaplayer.rate == 1.0 else { break }
            mediaplayer.fastForward(atRate: 20.0)
        case .cancelled:
            fallthrough
        case .failed:
            fallthrough
        case .ended:
            #if os(tvOS)
            progressBar.hint = .none
            #endif
            mediaplayer.rate = 1.0
            resetIdleTimer()
        default:
            break
        }
    }
    
    @IBAction func rewindHeld(_ sender: UIGestureRecognizer) {
        switch sender.state {
        case .began:
            fallthrough
        case .changed:
            #if os(tvOS)
            progressBar.hint = .rewind
            #endif
            guard mediaplayer.rate == 1.0 else { break }
            mediaplayer.rewind(atRate: 20.0)
        case .cancelled:
            fallthrough
        case .failed:
            fallthrough
        case .ended:
            #if os(tvOS)
            progressBar.hint = .none
            #endif
            mediaplayer.rate = 1.0
            resetIdleTimer()
        default:
            break
        }
    }
    
    @IBAction func didFinishPlaying() {
        mediaplayer.delegate = nil
        mediaplayer.stop()
        
        removeRemoteCommandCenterHandlers()
        endReceivingScreenNotifications()
        
        streamer.cancelStreamingAndDeleteData(UserDefaults.standard.bool(forKey: "removeCacheOnPlayerExit"))
        
        setProgress(status: .finished)
        NotificationCenter.default.removeObserver(self, name: .PTTorrentStatusDidChange, object: nil)
        
        dismiss(animated: true)
    }
    
    // MARK: - Public vars
    
    weak var delegate: PCTPlayerViewControllerDelegate?
    var subtitles: Dictionary<String, [Subtitle]> {
        return media.subtitles
    }
    var currentSubtitle: Subtitle? {
        didSet {
            if let subtitle = currentSubtitle {
                PopcornKit.downloadSubtitleFile(subtitle.link, downloadDirectory: directory, completion: { (subtitlePath, error) in
                    guard let subtitlePath = subtitlePath else { return }
                    self.mediaplayer.addPlaybackSlave(subtitlePath, type: .subtitle, enforce: true)
                })
            } else {
                mediaplayer.currentVideoSubTitleIndex = NSNotFound // Remove all subtitles
            }
        }
    }
    
    // MARK: - Private vars
    
    private (set) var mediaplayer = VLCMediaPlayer()
    private (set) var url: URL!
    private (set) var directory: URL!
    private (set) var localPathToMedia: URL!
    private (set) var media: Media!
    private (set) var streamer: PTTorrentStreamer!
    internal var nextEpisode: Episode?
    internal var startPosition: Float = 0.0
    private var idleWorkItem: DispatchWorkItem?
    internal var shouldHideStatusBar = true
    private let NSNotFound: Int32 = -1
    private var imageGenerator: AVAssetImageGenerator!
    internal var workItem: DispatchWorkItem?
    private var resumePlayback = false
    internal var streamDuration: Float {
        guard let remaining = mediaplayer.remainingTime?.value?.floatValue, let elapsed = mediaplayer.time?.value?.floatValue else { return Float(CMTimeGetSeconds(imageGenerator.asset.duration) * 1000) }
        return fabsf(remaining) + elapsed
    }
    internal var nowPlayingInfo: [String: Any]? {
        get {
            return MPNowPlayingInfoCenter.default().nowPlayingInfo
        } set {
            MPNowPlayingInfoCenter.default().nowPlayingInfo = newValue
        }
    }
    
    // MARK: - Player functions
    
    func play(_ media: Media, fromURL url: URL, localURL local: URL, progress fromPosition: Float, nextEpisode: Episode? = nil, directory: URL, streamer: PTTorrentStreamer) {
        self.url = url
        self.localPathToMedia = local
        self.media = media
        self.startPosition = fromPosition
        self.nextEpisode = nextEpisode
        self.directory = directory
        self.imageGenerator = AVAssetImageGenerator(asset: AVAsset(url: local))
        self.streamer = streamer
    }
    
    // MARK: - Options view controller delegate
    
    func didSelectSubtitle(_ subtitle: Subtitle?) {
        currentSubtitle = subtitle
    }
    
    func didSelectAudioDelay(_ delay: Int) {
        mediaplayer.currentAudioPlaybackDelay = Int(1e6) * delay
    }
    
    
    func didSelectSubtitleDelay(_ delay: Int) {
        mediaplayer.currentVideoSubTitleDelay = Int(1e6) * delay
    }
    
    func didSelectEncoding(_ encoding: String) {
        mediaplayer.media.addOptions([vlcSettingTextEncoding: encoding])
    }
    
    func screenshotAtTime(_ time: NSNumber) -> UIImage? {
        guard let image = try? imageGenerator.copyCGImage(at: CMTimeMakeWithSeconds(time.doubleValue/1000.0, preferredTimescale: 1000), actualTime: nil) else { return nil }
        return UIImage(cgImage: image)
    }
    
    // MARK: - View Methods
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard mediaplayer.state == .stopped || mediaplayer.state == .opening else { return }
        if startPosition > 0.0 {
            let isRegular = traitCollection.horizontalSizeClass == .regular && traitCollection.verticalSizeClass == .regular
            let style: UIAlertController.Style = isRegular ? .alert : .actionSheet
            let continueWatchingAlert = UIAlertController(title: nil, message: nil, preferredStyle: style)
            
            #if os(tvOS)
                NotificationCenter.default.addObserver(self, selector: #selector(alertFocusDidChange(_:)), name: .UIViewControllerFocusedViewDidChange, object: continueWatchingAlert)
            #endif
            
            self.loadingActivityIndicatorView.isHidden = true
            
            
            continueWatchingAlert.addAction(UIAlertAction(title: "Resume Playing".localized, style: .default, handler:{ action in
                UIDevice.current.userInterfaceIdiom == .tv ? NotificationCenter.default.removeObserver(self, name: .UIViewControllerFocusedViewDidChange, object: continueWatchingAlert) : ()
                self.resumePlayback = true
                self.loadingActivityIndicatorView.isHidden = false
                self.mediaplayer.play()
            }))
            continueWatchingAlert.addAction(UIAlertAction(title: "Start from Beginning".localized, style: .default, handler: { action in
                UIDevice.current.userInterfaceIdiom == .tv ? NotificationCenter.default.removeObserver(self, name: .UIViewControllerFocusedViewDidChange, object: continueWatchingAlert) : ()
                self.loadingActivityIndicatorView.isHidden = false
                self.mediaplayer.play()
            }))
            continueWatchingAlert.popoverPresentationController?.sourceView = progressBar
            present(continueWatchingAlert, animated: true)
        } else {
            mediaplayer.play()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mediaplayer.delegate = self
        mediaplayer.drawable = movieView
        mediaplayer.media = VLCMedia(url: url)
        
        NotificationCenter.default.addObserver(self, selector: #selector(torrentStatusDidChange(_:)), name: .PTTorrentStatusDidChange, object: streamer)
        
        let settings = SubtitleSettings.shared
        media.getSubtitles(orWithFilePath: self.localPathToMedia){ subtitles in
            self.media.subtitles = subtitles
            if let preferredLanguage = settings.language {
                self.currentSubtitle = subtitles[preferredLanguage]?.first
            }
        }
        (mediaplayer as VLCFontAppearance).setTextRendererFontSize!(NSNumber(value: settings.size.rawValue))
        (mediaplayer as VLCFontAppearance).setTextRendererFontColor!(NSNumber(value: settings.color.hexInt()))
        (mediaplayer as VLCFontAppearance).setTextRendererFont!(settings.font.fontName as NSString)
        (mediaplayer as VLCFontAppearance).setTextRendererFontForceBold!(NSNumber(booleanLiteral: settings.style == .bold || settings.style == .boldItalic))
        
        mediaplayer.media.addOptions([vlcSettingTextEncoding: settings.encoding])
        
        if let first = tapOnVideoRecognizer, let second = doubleTapToZoomOnVideoRecognizer {
            first.require(toFail: second)
        }
        
        subtitleSwitcherButton?.isHidden = subtitles.count == 0
        subtitleSwitcherButtonWidthConstraint?.constant = subtitleSwitcherButton?.isHidden == true ? 0 : 24
        
        if #available(iOS 10.0,tvOS 10.0,*){
            try? AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback,mode: AVAudioSession.Mode(rawValue: convertFromAVAudioSessionMode(AVAudioSession.Mode.moviePlayback)), options: [.allowBluetoothA2DP,.allowAirPlay])
        }
        
        
        #if os(iOS)
            volumeSliderView?.addSubview(volumeView)
            if let slider = volumeView.subviews.compactMap({$0 as? UISlider}).first {
                slider.addTarget(self, action: #selector(volumeChanged(forSlider:)), for: .valueChanged)
            }
        #elseif os(tvOS)
            let gesture = SiriRemoteGestureRecognizer(target: self, action: #selector(touchLocationDidChange(_:)))
            gesture.delegate = self
            view.addGestureRecognizer(gesture)
            
            let clickGesture = SiriRemoteGestureRecognizer(target: self, action: #selector(clickGesture(_:)))
            clickGesture.delegate = self
            view.addGestureRecognizer(clickGesture)
            
            didSelectEqualizerProfile(.fullDynamicRange)
        #endif
    }
    
    // MARK: - Player changes notifications
    
    @objc func torrentStatusDidChange(_ aNotification: Notification) {
        if let streamer = aNotification.object as? PTTorrentStreamer {
            progressBar?.bufferProgress = streamer.torrentStatus.totalProgress
        }
    }
    
    func mediaPlayerTimeChanged(_ aNotification: Notification!) {
        if loadingActivityIndicatorView.isHidden == false {
            #if os(iOS)
                progressBar.subviews.first(where: {!$0.subviews.isEmpty})?.subviews.forEach({ $0.isHidden = false })
            #endif
            loadingActivityIndicatorView.isHidden = true
            
            addRemoteCommandCenterHandlers()
            beginReceivingScreenNotifications()
            configureNowPlayingInfo()
            
            resetIdleTimer()
        }
        
        if resumePlayback && mediaplayer.isSeekable {
            resumePlayback = streamDuration == 0 ? true:false // check if the current stream length is available if not retry to go to previous position
            if resumePlayback == false {
                let time = NSNumber(value: startPosition * streamDuration)
                mediaplayer.time = VLCTime(number: time)
            }
        }
        
        playPauseButton?.setImage(UIImage(named: "Pause"), for: .normal)
        
        progressBar.isBuffering = false
        
        progressBar.remainingTimeLabel.text = mediaplayer.remainingTime.stringValue
        progressBar.elapsedTimeLabel.text = mediaplayer.time.stringValue
        progressBar.progress = mediaplayer.position
        
        if nextEpisode != nil && (mediaplayer.remainingTime.intValue/1000) == -31 && presentedViewController == nil {
            performSegue(withIdentifier: "showUpNext", sender: nil)
        } else if (mediaplayer.remainingTime.intValue/1000) < -31, let vc = presentedViewController as? UpNextViewController {
            vc.dismiss(animated: true)
        }
    }
    
    func mediaPlayerStateChanged(_ aNotification: Notification!) {
        resetIdleTimer()
        progressBar.isBuffering = false
        nowPlayingInfo?[MPNowPlayingInfoPropertyElapsedPlaybackTime] = (mediaplayer.time.value?.doubleValue ?? 0)/1000
        switch mediaplayer.state {
        case .error:
            fallthrough
        case .ended:
            fallthrough
        case .stopped:
            didFinishPlaying()
        case .paused:
            setProgress(status: .paused)
            playPauseButton?.setImage(UIImage(named: "Play"), for: .normal)
            nowPlayingInfo?[MPNowPlayingInfoPropertyPlaybackRate] = 0.0
        case .playing:
            playPauseButton?.setImage(UIImage(named: "Pause"), for: .normal)
            setProgress(status: .watching)
            nowPlayingInfo?[MPNowPlayingInfoPropertyPlaybackRate] = Double(mediaplayer.rate)
        case .buffering:
            progressBar.isBuffering = true
        default:
            break
        }
    }
    
    
    @IBAction func toggleControlsVisible() {
        shouldHideStatusBar = overlayViews.first!.isHidden
        UIView.animate(withDuration: 0.25, animations: {
            if self.overlayViews.first!.isHidden {
                self.overlayViews.forEach({
                    $0.alpha = 1.0
                    $0.isHidden = false
                })
            } else {
                self.overlayViews.forEach({ $0.alpha = 0.0 })
                self.showVolumeConstraint?.priority = UILayoutPriority(500)
            }
            #if os(iOS)
                self.setNeedsStatusBarAppearanceUpdate()
                if #available(iOS 11.0, *) {
                    self.setNeedsUpdateOfHomeIndicatorAutoHidden()
                }
            #endif
         }, completion: { finished in
            if self.overlayViews.first!.alpha == 0.0 {
                self.overlayViews.forEach({ $0.isHidden = true })
            }
            self.resetIdleTimer()
        }) 
    }
    
    // MARK: - Timers
    
    func resetIdleTimer() {
        idleWorkItem?.cancel()
        idleWorkItem = DispatchWorkItem() { [unowned self] in
            if !self.progressBar.isHidden && self.mediaplayer.isPlaying && !self.progressBar.isScrubbing && !self.progressBar.isBuffering && self.mediaplayer.rate == 1.0  && self.movieView.isDescendant(of: self.view) // If paused, scrubbing, fast forwarding, loading or mirroring, cancel work Item so UI doesn't disappear
            {
                self.toggleControlsVisible()
            }
        }
        
        let delay: TimeInterval = UIDevice.current.userInterfaceIdiom == .tv ? 3 : 5
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: idleWorkItem!)
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {    
        return true
    }
    
    func setProgress(status: Trakt.WatchedStatus) {
        if let movie = media as? Movie {
            WatchedlistManager<Movie>.movie.setCurrentProgress(progressBar.progress, for: movie.id, with: status)
        } else if let episode = media as? Episode {
            WatchedlistManager<Episode>.episode.setCurrentProgress(progressBar.progress, for: episode.id, with: status)
        }
    }
    
    // MARK: UpNextViewControllerDelegate
    
    func viewController(_ viewController: UpNextViewController, proceedToNextVideo proceed: Bool) {
        let completion: (() -> Void) = { [unowned self] in
            if proceed {
                self.didFinishPlaying()
                self.delegate?.playNext(self.nextEpisode!)
            }
        }
        if UIDevice.current.userInterfaceIdiom == .tv {
            viewController.dismiss(animated: true, completion: completion)
        } else {
            UIView.animate(withDuration: .default, animations: { 
                self.upNextContainerView?.transform = .identity
            }) { (_) in
                completion()
            }
            
        }
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showUpNext", let vc = segue.destination as? UpNextViewController, let episode = nextEpisode {
            vc.delegate = self
            vc.modalPresentationStyle = .custom
            
            vc.loadViewIfNeeded()
            
            if UIDevice.current.userInterfaceIdiom == .tv {
                vc.titleLabel?.text = "Episode".localized + " \(episode.episode) - " + episode.title
                vc.summaryView?.text = episode.summary
            } else {
                vc.titleLabel?.text = episode.title
                vc.subtitleLabel?.text = "Season".localized + " \(episode.season) " + "Episode".localized + " \(episode.episode)"
                vc.infoLabel?.text = episode.show?.title
            }
            
            TMDBManager.shared.getEpisodeScreenshots(forShowWithImdbId: episode.show?.id, orTMDBId: episode.show?.tmdbId, season: episode.season, episode: episode.episode) { [weak self, weak vc] (tmdbId, image, error) in
                self?.nextEpisode?.largeBackgroundImage = image
                    
                if let image = image, let url = URL(string: image) {
                    vc?.imageView.af_setImage(withURL: url)
                }
                
                self?.nextEpisode?.getSubtitles { (subtitles) in
                    self?.nextEpisode?.subtitles = subtitles
                }
            }
        }
        
        #if os(iOS)
            
            if segue.identifier == "showSubtitles",
                let navigationController = segue.destination as? UINavigationController,
                let vc = navigationController.viewControllers.first as? OptionsTableViewController {
                vc.subtitles = subtitles
                vc.currentSubtitle = currentSubtitle
                vc.currentSubtitleDelay = mediaplayer.currentVideoSubTitleDelay/Int(1e6)
                vc.currentAudioDelay = mediaplayer.currentAudioPlaybackDelay/Int(1e6)
                vc.delegate = self
                segue.destination.popoverPresentationController?.delegate = self
            } else if segue.identifier == "showDevices", let vc = (segue.destination as? UINavigationController)?.viewControllers.first as? GoogleCastTableViewController {
                object_setClass(vc, StreamToDevicesTableViewController.self)
                vc.delegate = self
                segue.destination.popoverPresentationController?.delegate = self
            }
            
        #endif
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(true)
        if self.isBeingDismissed {
            idleWorkItem?.cancel()
            media = nil
            mediaplayer.delegate = nil
            movieView = nil
        }
        
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        guard identifier == "showUpNext",(mediaplayer.remainingTime.intValue/1000) >= -31
        else{
            return true
        }
        return false
    }
}



// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromAVAudioSessionMode(_ input: AVAudioSession.Mode) -> String {
	return input.rawValue
}
