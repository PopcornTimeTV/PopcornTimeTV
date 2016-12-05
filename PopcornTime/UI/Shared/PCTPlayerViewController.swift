

import UIKit
import MediaPlayer
import PopcornTorrent
import PopcornKit

#if os(tvOS)
    import TVMLKitchen
#endif

protocol PCTPlayerViewControllerDelegate: class {
    func playNext(_ episode: Episode)
    
    #if os(iOS)
        func presentCastPlayer(_ media: Media, videoFilePath: URL, startPosition: TimeInterval)
    #endif
}

/// Optional functions:
extension PCTPlayerViewControllerDelegate {
    func playNext(_ episode: Episode) {}
}

class PCTPlayerViewController: UIViewController, VLCMediaPlayerDelegate, UIGestureRecognizerDelegate {
    
    // MARK: - IBOutlets
    @IBOutlet var movieView: UIView!
    @IBOutlet var loadingActivityIndicatorView: UIView!
    @IBOutlet var upNextView: UpNextView!
    
    @IBOutlet var overlayViews: [UIView]!
    
    #if os(tvOS)
        @IBOutlet var progressBar: VLCTransportBar!
        @IBOutlet var dimmerView: UIView!
        @IBOutlet var infoHelperView: UIView!
    
        var lastTranslation: CGFloat = 0.0
        let interactor = OptionsPercentDrivenInteractiveTransition()
    #elseif os(iOS)
        @IBOutlet var progressBar: ProgressBar!
        @IBOutlet var screenshotImageView: UIImageView!
    
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
    
        @IBOutlet var playPauseButton: UIButton!
        @IBOutlet var subtitleSwitcherButton: UIButton!
        @IBOutlet var videoDimensionsButton: UIButton!
    
        @IBOutlet var tapOnVideoRecognizer: UITapGestureRecognizer!
        @IBOutlet var doubleTapToZoomOnVideoRecognizer: UITapGestureRecognizer!
    
        @IBOutlet var regularConstraints: [NSLayoutConstraint]!
        @IBOutlet var compactConstraints: [NSLayoutConstraint]!
        @IBOutlet var duringScrubbingConstraints: NSLayoutConstraint!
        @IBOutlet var finishedScrubbingConstraints: NSLayoutConstraint!
        @IBOutlet var subtitleSwitcherButtonWidthConstraint: NSLayoutConstraint!
    
        @IBOutlet var scrubbingSpeedLabel: UILabel!
    #endif
    
    
    
    // MARK: - Slider actions

    func positionSliderDidDrag() {
        let time = NSNumber(value: Float(progressBar.scrubbingProgress * streamDuration))
        let remainingTime = NSNumber(value: time.floatValue - Float(streamDuration))
        progressBar.remainingTimeLabel.text = VLCTime(number: remainingTime).stringValue
        progressBar.scrubbingTimeLabel.text = VLCTime(number: time).stringValue
        workItem?.cancel()
        workItem = DispatchWorkItem { [weak self] in
            if let image = self?.screenshotAtTime(time) {
                #if os(tvOS)
                    self?.progressBar.screenshot = image
                #elseif os(iOS)
                    self?.screenshotImageView.image = image
                #endif
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25, execute: workItem!)
    }
    
    func positionSliderAction() {
        resetIdleTimer()
        mediaplayer.play()
        if mediaplayer.isSeekable {
            let time = NSNumber(value: Float(progressBar.scrubbingProgress * streamDuration))
            mediaplayer.time = VLCTime(number: time)
        }
    }
    
    // MARK: - Button actions
    
    @IBAction func playandPause() {
        #if os(tvOS)
            // Make fake gesture to trick clickGesture: into recognising the touch.
            let gesture = VLCSiriRemoteGestureRecognizer(target: nil, action: nil)
            gesture.isClick = true
            clickGesture(gesture)
        #elseif os(iOS)
            mediaplayer.isPlaying ? mediaplayer.pause() : mediaplayer.play()
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
        default:
            break
        }
    }
    
    @IBAction func didFinishPlaying() {
        mediaplayer.stop()
        PTTorrentStreamer.shared().cancelStreamingAndDeleteData(UserDefaults.standard.bool(forKey: "removeCacheOnPlayerExit"))
        #if os(tvOS)
            OperationQueue.main.addOperation {
                Kitchen.appController.navigationController.popViewController(animated: true)
            }
        #elseif os(iOS)
            dismiss(animated: true, completion: nil)
        #endif
    }
    
    // MARK: - Public vars
    
    weak var delegate: PCTPlayerViewControllerDelegate?
    var subtitles = [Subtitle]()
    var currentSubtitle: Subtitle? {
        didSet {
            if let subtitle = currentSubtitle {
                PopcornKit.downloadSubtitleFile(subtitle.link, downloadDirectory: directory, completion: { (subtitlePath, error) in
                    guard let subtitlePath = subtitlePath else { return }
                    self.mediaplayer.openVideoSubTitles(fromFile: subtitlePath.relativePath)
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
    private var startPosition: Float = 0.0
    private var idleTimer: Timer!
    internal var shouldHideStatusBar = true
    private let NSNotFound: Int32 = -1
    private var imageGenerator: AVAssetImageGenerator!
    private var workItem: DispatchWorkItem?
    internal var streamDuration: CGFloat {
        guard let remaining = mediaplayer.remainingTime?.value?.floatValue, let elapsed = mediaplayer.time?.value?.floatValue else { return 0.0 }
        return CGFloat((fabsf(remaining) + elapsed))
    }
    
    // MARK: - Player functions
    
    func play(_ media: Media, fromURL url: URL, localURL local: URL, progress fromPosition: Float, nextEpisode: Episode? = nil, directory: URL) {
        self.url = url
        self.localPathToMedia = local
        self.media = media
        self.startPosition = fromPosition
        self.nextEpisode = nextEpisode
        self.directory = directory
        if let subtitles = media.subtitles {
            self.subtitles = subtitles
        }
        self.imageGenerator = AVAssetImageGenerator(asset: AVAsset(url: local))
    }
    
    func didSelectSubtitle(_ subtitle: Subtitle?) {
        currentSubtitle = subtitle
    }
    
    func screenshotAtTime(_ time: NSNumber) -> UIImage? {
        guard let image = try? imageGenerator.copyCGImage(at: CMTimeMakeWithSeconds(time.doubleValue/1000.0, 1000), actualTime: nil) else { return nil }
        return UIImage(cgImage: image)
    }
    
    // MARK: - View Methods
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(mediaPlayerStateChanged), name: NSNotification.Name(rawValue: VLCMediaPlayerStateChanged), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(mediaPlayerTimeChanged), name: NSNotification.Name(rawValue: VLCMediaPlayerTimeChanged), object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard !mediaplayer.isPlaying else { return }
        if startPosition > 0.0 {
            let style: UIAlertControllerStyle = (traitCollection.horizontalSizeClass == .regular && traitCollection.verticalSizeClass == .regular) ? .alert : .actionSheet
            let continueWatchingAlert = UIAlertController(title: "Continue watching?", message: "Looks like you've already started watching this, would you like to start from the start or continue where you left off.", preferredStyle: style)
            continueWatchingAlert.addAction(UIAlertAction(title: "Yes, continue from where I left off", style: .default, handler:{ action in
                self.mediaplayer.play()
                self.mediaplayer.position = self.startPosition
                self.progressBar.progress = CGFloat(self.startPosition)
            }))
            continueWatchingAlert.addAction(UIAlertAction(title: "Nope, play from the begining", style: .default, handler: { action in
                self.mediaplayer.play()
            }))
            continueWatchingAlert.popoverPresentationController?.sourceView = progressBar
            present(continueWatchingAlert, animated: true, completion: nil)
        } else {
            mediaplayer.play()
        }
        ThemeSongManager.shared.stopTheme() // Make sure theme song isn't playing.
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mediaplayer.delegate = self
        mediaplayer.drawable = movieView
        mediaplayer.media = VLCMedia(url: url)
        progressBar.progress = 0
        mediaplayer.audio.volume = 200
        
        let settings = SubtitleSettings()
        currentSubtitle = currentSubtitle ?? subtitles.filter({ $0.language == settings.language }).first
        (mediaplayer as VLCFontAppearance).setTextRendererFontSize!(NSNumber(value: settings.size))
        (mediaplayer as VLCFontAppearance).setTextRendererFontColor!(NSNumber(value: settings.color.hexInt()))
        (mediaplayer as VLCFontAppearance).setTextRendererFont!(settings.font.familyName as NSString)
        (mediaplayer as VLCFontAppearance).setTextRendererFontForceBold!(NSNumber(booleanLiteral: settings.style == .bold || settings.style == .boldItalic))
        mediaplayer.media.addOptions([vlcSettingTextEncoding: settings.encoding])

//        if let nextMedia = nextMedia {
//            upNextView.delegate = self
//            upNextView.nextEpisodeInfoLabel.text = "Season \(nextMedia.season) Episode \(nextMedia.episode)"
//            upNextView.nextEpisodeTitleLabel.text = nextMedia.title
//            upNextView.nextShowTitleLabel.text = nextMedia.show!.title
//            TraktManager.shared.getEpisodeMetadata(nextMedia.show.id, episodeNumber: nextMedia.episode, seasonNumber: nextMedia.season, completion: { (image, _, imdb, error) in
//                guard let imdb = imdb else { return }
//                self.nextMedia?.largeBackgroundImage = image
//                if let image = image {
//                   self.upNextView.nextEpisodeThumbImageView.af_setImage(withURL: URL(string: image)!)
//                } else {
//                    self.upNextView.nextEpisodeThumbImageView.image = UIImage(named: "Placeholder")
//                }
//                    SubtitlesManager.shared.search(imdbId: imdb, completion: { (subtitles, error) in
//                        guard error == nil else { return }
//                        self.nextMedia?.subtitles = subtitles
//                    })
//            })
//        }
        #if os(iOS)
            view.addSubview(volumeView)
            if let slider = volumeView.subviews.flatMap({$0 as? UISlider}).first {
                slider.addTarget(self, action: #selector(volumeChanged), for: .valueChanged)
            }
            tapOnVideoRecognizer.require(toFail: doubleTapToZoomOnVideoRecognizer)
            
            subtitleSwitcherButton.isHidden = subtitles.count == 0
            subtitleSwitcherButtonWidthConstraint.constant = subtitleSwitcherButton.isHidden == true ? 0 : 24
        #elseif os(tvOS)
            let gesture = VLCSiriRemoteGestureRecognizer(target: self, action: #selector(touchLocationDidChange(_:)))
            gesture.delegate = self
            view.addGestureRecognizer(gesture)
            
            let clickGesture = VLCSiriRemoteGestureRecognizer(target: self, action: #selector(clickGesture(_:)))
            clickGesture.delegate = self
            view.addGestureRecognizer(clickGesture)
        #endif
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        mediaplayer.pause()
        NotificationCenter.default.removeObserver(self)
        if idleTimer != nil {
            idleTimer.invalidate()
            idleTimer = nil
        }
    }
    
    // MARK: - Player changes notifications
    
    func mediaPlayerStateChanged() {
        resetIdleTimer()
        let manager: WatchedlistManager = media is Movie ? .movie : .episode
        switch mediaplayer.state {
        case .error:
            fallthrough
        case .ended:
            fallthrough
        case .stopped:
            manager.setCurrentProgress(Float(progressBar.progress), forId: media.id, withStatus: .finished)
            didFinishPlaying()
        case .paused:
            manager.setCurrentProgress(Float(progressBar.progress), forId: media.id, withStatus: .paused)
            #if os(iOS)
                playPauseButton.setImage(UIImage(named: "Play"), for: .normal)
            #endif
        case .playing:
            #if os(iOS)
                playPauseButton.setImage(UIImage(named: "Pause"), for: .normal)
            #endif
            manager.setCurrentProgress(Float(progressBar.progress), forId: media.id, withStatus: .watching)
        case .buffering:
            progressBar.isBuffering = true
        default:
            break
        }
    }
    
    func mediaPlayerTimeChanged() {
        if loadingActivityIndicatorView.isHidden == false {
            #if os(iOS)
                progressBar.subviews.first(where: {!$0.subviews.isEmpty})?.subviews.forEach({ $0.isHidden = false })
            #endif
            loadingActivityIndicatorView.isHidden = true
        }
        progressBar.isBuffering = false
        progressBar.bufferProgress = CGFloat(PTTorrentStreamer.shared().torrentStatus.totalProgreess)
        progressBar.remainingTimeLabel.text = mediaplayer.remainingTime.stringValue
        progressBar.elapsedTimeLabel.text = mediaplayer.time.stringValue
        progressBar.progress = CGFloat(mediaplayer.position)
//        if nextMedia != nil && (mediaplayer.remainingTime.intValue/1000) == -30 {
//            upNextView.show()
//        } else if (mediaplayer.remainingTime.intValue/1000) < -30 && !upNextView.isHidden {
//            upNextView.hide()
//        }
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
        if idleTimer == nil {
            let delay: TimeInterval = UIDevice.current.userInterfaceIdiom == .tv ? 3 : 5
            idleTimer = Timer.scheduledTimer(timeInterval: delay, target: self, selector: #selector(idleTimerExceeded), userInfo: nil, repeats: false)
            if !mediaplayer.isPlaying || !loadingActivityIndicatorView.isHidden || progressBar.isScrubbing || progressBar.isBuffering || mediaplayer.rate != 1.0 // If paused, scrubbing, fast forwarding or loading, cancel timer so UI doesn't disappear
            {
                idleTimer.invalidate()
                idleTimer = nil
            }
        } else {
            idleTimer.invalidate()
            idleTimer = nil
            resetIdleTimer()
        }
    }
    
    func idleTimerExceeded() {
        idleTimer = nil
        if !progressBar.isHidden {
            toggleControlsVisible()
        }
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {    
        return true
    }
    
}
/**
 Protocol wrapper for private subtitle appearance API in MobileVLCKit. Can be toll free bridged from VLCMediaPlayer. Example for changing font:
 
        let mediaPlayer = VLCMediaPlayer()
        (mediaPlayer as VLCFontAppearance).setTextRendererFont!("HelveticaNueve")
 */
@objc protocol VLCFontAppearance {
    /**
     Change color of subtitle font.
     
     [All colors available here](http://www.nameacolor.com/Color%20numbers.htm)
     
     - Parameter fontColor: An `NSNumber` wrapped hexInt (`UInt32`) indicating the color. Eg. Black: 0, White: 16777215, etc.
     */
    @objc optional func setTextRendererFontColor(_ fontColor: NSNumber)
    /**
     Toggle bold on subtitle font.
     
     - Parameter fontForceBold: `NSNumber` wrapped `Bool`.
     */
    @objc optional func setTextRendererFontForceBold(_ fontForceBold: NSNumber)
    /**
     Change the subtitle font.
     
     - Parameter fontname: `NSString` representation of font name. Eg `UIFonts` familyName property.
     */
    @objc optional func setTextRendererFont(_ fontname: NSString)
    /**
     Change the subtitle font size.
     
     - Parameter fontname: `NSNumber` wrapped `Int` of the fonts size.
     
     - Important: Provide the font in reverse size as `libvlc` sets the text matrix to the identity matrix which reverses the font size. Ie. 5pt is really big and 100pt is really small.
     */
    @objc optional func setTextRendererFontSize(_ fontSize: NSNumber)
}

extension VLCMediaPlayer: VLCFontAppearance {}
