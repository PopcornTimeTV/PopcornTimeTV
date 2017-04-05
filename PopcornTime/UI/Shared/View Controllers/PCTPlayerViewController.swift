

import UIKit
import MediaPlayer
import PopcornTorrent
import PopcornKit


protocol PCTPlayerViewControllerDelegate: class {
    func playNext(_ episode: Episode)
    
    #if os(iOS)
        func presentCastPlayer(_ media: Media, videoFilePath: URL)
    #endif
}

/// Optional functions
extension PCTPlayerViewControllerDelegate {
    func playNext(_ episode: Episode) {}
}

class PCTPlayerViewController: UIViewController, VLCMediaPlayerDelegate, UIGestureRecognizerDelegate, UpNextViewDelegate, OptionsViewControllerDelegate {
    
    // MARK: - IBOutlets
    @IBOutlet var movieView: UIView!
    @IBOutlet var loadingActivityIndicatorView: UIView!
    @IBOutlet var upNextView: UpNextView!
    @IBOutlet var progressBar: ProgressBar!
    
    @IBOutlet var overlayViews: [UIView] = []
    
    // tvOS exclusive
    @IBOutlet var dimmerView: UIView?
    @IBOutlet var infoHelperView: UIView?
    
    var lastTranslation: CGFloat = 0.0
    
    // iOS exclusive
    @IBOutlet var airPlayingView: UIView?
    @IBOutlet var screenshotImageView: UIImageView?
    
    @IBOutlet var playPauseButton: UIButton?
    @IBOutlet var subtitleSwitcherButton: UIButton?
    @IBOutlet var videoDimensionsButton: UIButton?
    
    @IBOutlet var tapOnVideoRecognizer: UITapGestureRecognizer?
    @IBOutlet var doubleTapToZoomOnVideoRecognizer: UITapGestureRecognizer?
    
    @IBOutlet var regularConstraints: [NSLayoutConstraint] = []
    @IBOutlet var compactConstraints: [NSLayoutConstraint] = []
    @IBOutlet var duringScrubbingConstraints: NSLayoutConstraint?
    @IBOutlet var finishedScrubbingConstraints: NSLayoutConstraint?
    @IBOutlet var subtitleSwitcherButtonWidthConstraint: NSLayoutConstraint?
    
    @IBOutlet var scrubbingSpeedLabel: UILabel?
    
    #if os(iOS)
        @IBOutlet var volumeSlider: BarSlider! {
            didSet {
                volumeSlider.setValue(AVAudioSession.sharedInstance().outputVolume, animated: false)
            }
        }
    
        internal var volumeView: MPVolumeView = {
            let view = MPVolumeView(frame: CGRect(x: -1000, y: -1000, width: 100, height: 100))
            view.sizeToFit()
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
        
        PTTorrentStreamer.shared().cancelStreamingAndDeleteData(UserDefaults.standard.bool(forKey: "removeCacheOnPlayerExit"))
        
        setProgress(status: .finished)
        NotificationCenter.default.removeObserver(self, name: .PTTorrentStatusDidChange, object: nil)
        
        dismiss(animated: true)
    }
    
    // MARK: - Public vars
    
    weak var delegate: PCTPlayerViewControllerDelegate?
    var subtitles: [Subtitle] {
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
    internal var nowPlayingInfo: [String : Any]? {
        get {
            return MPNowPlayingInfoCenter.default().nowPlayingInfo
        } set {
            MPNowPlayingInfoCenter.default().nowPlayingInfo = newValue
        }
    }
    
    // MARK: - Player functions
    
    func play(_ media: Media, fromURL url: URL, localURL local: URL, progress fromPosition: Float, nextEpisode: Episode? = nil, directory: URL) {
        self.url = url
        self.localPathToMedia = local
        self.media = media
        self.startPosition = fromPosition
        self.nextEpisode = nextEpisode
        self.directory = directory
        self.imageGenerator = AVAssetImageGenerator(asset: AVAsset(url: local))
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
        guard let image = try? imageGenerator.copyCGImage(at: CMTimeMakeWithSeconds(time.doubleValue/1000.0, 1000), actualTime: nil) else { return nil }
        return UIImage(cgImage: image)
    }
    
    // MARK: - View Methods
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard mediaplayer.state == .stopped || mediaplayer.state == .opening else { return }
        if startPosition > 0.0 {
            let isRegular = traitCollection.horizontalSizeClass == .regular && traitCollection.verticalSizeClass == .regular
            let style: UIAlertControllerStyle = isRegular ? .alert : .actionSheet
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
            continueWatchingAlert.addAction(UIAlertAction(title: "Start from Begining".localized, style: .default, handler: { action in
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
        
        NotificationCenter.default.addObserver(self, selector: #selector(torrentStatusDidChange(_:)), name: .PTTorrentStatusDidChange, object: nil)
        
        let settings = SubtitleSettings.shared
        (mediaplayer as VLCFontAppearance).setTextRendererFontSize!(NSNumber(value: settings.size.rawValue))
        (mediaplayer as VLCFontAppearance).setTextRendererFontColor!(NSNumber(value: settings.color.hexInt()))
        (mediaplayer as VLCFontAppearance).setTextRendererFont!(settings.font.familyName as NSString)
        (mediaplayer as VLCFontAppearance).setTextRendererFontForceBold!(NSNumber(booleanLiteral: settings.style == .bold || settings.style == .boldItalic))
        if let preferredLanguage = settings.language {
            currentSubtitle = subtitles.first(where: {$0.language == preferredLanguage})
        }
        mediaplayer.media.addOptions([vlcSettingTextEncoding: settings.encoding])

        if let nextEpisode = nextEpisode {
            upNextView.delegate = self
            upNextView.subtitleLabel.text = "Season".localized + " \(nextEpisode.season) " + "Episode".localized + " \(nextEpisode.episode)"
            upNextView.titleLabel.text = nextEpisode.title
            upNextView.infoLabel.text = UIDevice.current.userInterfaceIdiom == .tv ? nextEpisode.summary : nextEpisode.show.title
            TMDBManager.shared.getEpisodeScreenshots(forShowWithImdbId: nextEpisode.show.id, orTMDBId: nextEpisode.show.tmdbId, season: nextEpisode.season, episode: nextEpisode.episode, completion: { (tmdbId, image, error) in
                self.nextEpisode?.largeBackgroundImage = image
                
                if let image = image, let url = URL(string: image) {
                    self.upNextView.imageView.af_setImage(withURL: url)
                }
                
                nextEpisode.getSubtitles(forId: nextEpisode.id) { (subtitles) in
                    self.nextEpisode?.subtitles = subtitles
                }
            })
        }
        
        if let first = tapOnVideoRecognizer, let second = doubleTapToZoomOnVideoRecognizer {
            first.require(toFail: second)
        }
        
        subtitleSwitcherButton?.isHidden = subtitles.count == 0
        subtitleSwitcherButtonWidthConstraint?.constant = subtitleSwitcherButton?.isHidden == true ? 0 : 24
        
        #if os(iOS)
            view.addSubview(volumeView)
            if let slider = volumeView.subviews.flatMap({$0 as? UISlider}).first {
                slider.addTarget(self, action: #selector(volumeChanged), for: .valueChanged)
            }
        #elseif os(tvOS)
            let gesture = SiriRemoteGestureRecognizer(target: self, action: #selector(touchLocationDidChange(_:)))
            gesture.delegate = self
            view.addGestureRecognizer(gesture)
            
            let clickGesture = SiriRemoteGestureRecognizer(target: self, action: #selector(clickGesture(_:)))
            clickGesture.delegate = self
            view.addGestureRecognizer(clickGesture)
        #endif
    }
    
    // MARK: - Player changes notifications
    
    func torrentStatusDidChange(_ notification: Notification) {
        let totalProgress = PTTorrentStreamer.shared().torrentStatus.totalProgress
        progressBar?.bufferProgress = totalProgress
    }
    
    func mediaPlayerTimeChanged(_ aNotification: Notification!) {
        if loadingActivityIndicatorView.isHidden == false {
            #if os(iOS)
                progressBar.subviews.first(where: {!$0.subviews.isEmpty})?.subviews.forEach({ $0.isHidden = false })
            #endif
            loadingActivityIndicatorView.isHidden = true
            
            if resumePlayback && mediaplayer.isSeekable {
                resumePlayback = false
                let time = NSNumber(value: startPosition * streamDuration)
                mediaplayer.time = VLCTime(number: time)
            }
            
            addRemoteCommandCenterHandlers()
            beginReceivingScreenNotifications()
            configureNowPlayingInfo()
            
            resetIdleTimer()
        }
        
        playPauseButton?.setImage(UIImage(named: "Pause"), for: .normal)
        
        progressBar.isBuffering = false
        
        progressBar.remainingTimeLabel.text = mediaplayer.remainingTime.stringValue
        progressBar.elapsedTimeLabel.text = mediaplayer.time.stringValue
        progressBar.progress = mediaplayer.position
        
        if nextEpisode != nil && (mediaplayer.remainingTime.intValue/1000) == -31 {
            upNextView.show()
        } else if (mediaplayer.remainingTime.intValue/1000) < -31 && !upNextView.isHidden {
            upNextView.hide()
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
            setProgress(status: .finished)
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
            }
            #if os(iOS)
            self.setNeedsStatusBarAppearanceUpdate()
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
        idleWorkItem = DispatchWorkItem() {
            if !self.progressBar.isHidden && self.mediaplayer.isPlaying && !self.progressBar.isScrubbing && !self.progressBar.isBuffering && self.mediaplayer.rate == 1.0  && self.view.subviews.contains(self.movieView) // If paused, scrubbing, fast forwarding, loading or mirroring, cancel work Item so UI doesn't disappear
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
    
    // MARK: Up next view delegate
    
    func constraintsWereUpdated(willHide hide: Bool) {
        UIView.animate(withDuration: .default, animations: {
            self.view.layoutIfNeeded()
        }, completion: { _ in
            if hide { self.upNextView.isHidden = true }
        })
    }
    
    func timerFinished() {
        didFinishPlaying()
        OperationQueue.main.addOperation {
            self.delegate?.playNext(self.nextEpisode!)
        }
    }
    
}
