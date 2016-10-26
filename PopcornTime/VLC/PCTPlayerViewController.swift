

import UIKit
import MediaPlayer
import PopcornTorrent
import PopcornKit
import TVMLKitchen

protocol PCTPlayerViewControllerDelegate: class {
    func playNext(_ episode: Episode)
}

class PCTPlayerViewController: UIViewController, VLCMediaPlayerDelegate, TabMenuCollectionViewCellDelegate, UIGestureRecognizerDelegate {
    
    func cellDidBecomeSelected(_ cell: TabMenuCollectionViewCell) {
        
    }
    
    // MARK: - IBOutlets
    @IBOutlet var movieView: UIView!
    @IBOutlet var progressBar: VLCTransportBar!
    @IBOutlet var bottomToolbar: VLCFrostedGlasView!
    @IBOutlet var loadingActivityIndicatorView: UIActivityIndicatorView!
    
    // MARK: - Slider actions

    func positionSliderDidDrag() {
        resetIdleTimer()
        let streamDuration = CGFloat((fabsf(mediaplayer.remainingTime.value.floatValue) + mediaplayer.time.value.floatValue))
        let time = NSNumber(value: Float(progressBar.progress * streamDuration))
        let remainingTime = NSNumber(value: time.floatValue - Float(streamDuration))
        progressBar.remainingTimeLabel.text = VLCTime(number: remainingTime).stringValue
        progressBar.elapsedTimeLabel.text = VLCTime(number: time).stringValue
        screenshotAtTime(time) { [weak self] (image) in
            self?.progressBar.screenshot = image
        }
    }
    func positionSliderAction() {
        mediaplayer.position = Float(progressBar.progress)
    }
    
    @IBAction func handlePositionSliderGesture(_ sender: UIPanGestureRecognizer) {
        let velocity = sender.velocity(in: view)
        if fabs(velocity.y) > fabs(velocity.x) || presentedViewController is OptionsViewController {
            presentOptionsViewController()
            handleOptionsGesture(sender)
            return
        }
        
        let translation = sender.translation(in: view)
        let offset = translation.x - lastTranslation
        
        switch sender.state {
        case .cancelled:
            fallthrough
        case .ended:
            positionSliderAction()
            lastTranslation = 0.0
        case .began:
            fallthrough
        case .changed:
            progressBar.progress = offset
            positionSliderDidDrag()
            lastTranslation = translation.x
        default:
            return
        }
    }
    
    func presentOptionsViewController() {
        if presentedViewController is OptionsViewController  {
            return
        }
        let destinationController = storyboard?.instantiateViewController(withIdentifier: "OptionsViewController") as! OptionsViewController
        destinationController.subtitles = subtitles
        destinationController.currentSubtitle = currentSubtitle
        destinationController.transitioningDelegate = self
        destinationController.modalPresentationStyle = .custom
        destinationController.interactor = interactor
        destinationController.delegate = self
        present(destinationController, animated: true, completion: nil)
    }

    
    func handleSiriRemoteGesture(_ sender: VLCSiriRemoteGestureRecognizer) {
        
    }
    
    // MARK: - Button actions
    
    @IBAction func playandPause() {
        if mediaplayer.isPlaying {
            mediaplayer.pause()
        } else {
            mediaplayer.play()
        }
    }
    @IBAction func fastForward() {
        mediaplayer.longJumpForward()
    }
    @IBAction func rewind() {
        mediaplayer.longJumpBackward()
    }
    @IBAction func fastForwardHeld(_ sender: UILongPressGestureRecognizer) {
        resetIdleTimer()
        switch sender.state {
        case .began:
            fallthrough
        case .changed:
            mediaplayer.mediumJumpForward()
        default:
            break
        }
        
    }
    @IBAction func rewindHeld(_ sender: UILongPressGestureRecognizer) {
        resetIdleTimer()
        switch sender.state {
        case .began:
            fallthrough
        case .changed:
            mediaplayer.mediumJumpBackward()
        default:
            break
        }
    }
    
    @IBAction func didFinishPlaying() {
        mediaplayer.stop()
        PTTorrentStreamer.shared().cancelStreamingAndDeleteData(UserDefaults.standard.bool(forKey: "removeCacheOnPlayerExit"))
        OperationQueue.main.addOperation {
            Kitchen.appController.navigationController.popViewController(animated: true)
        }
    }
    
    // MARK: - Public vars
    
    weak var delegate: PCTPlayerViewControllerDelegate?
    var subtitles = [Subtitle]()
    var currentSubtitle: Subtitle? {
        didSet {
            if let subtitle = currentSubtitle {
                mediaplayer.numberOfChapters(forTitle: Int32(subtitles.index(of: subtitle)!)) != NSNotFound ? mediaplayer.currentChapterIndex = Int32(subtitles.index(of: subtitle)!) : openSubtitles(URL(string: subtitle.link)!)
            } else {
                mediaplayer.currentChapterIndex = NSNotFound // Remove all subtitles
            }
        }
    }
    
    // MARK: - Private vars
    
    private (set) var mediaplayer = VLCMediaPlayer()
    private (set) var url: URL!
    private (set) var directory: URL!
    private (set) var media: Media!
    internal var nextMedia: Episode?
    private var startPosition: Float = 0.0
    private var idleTimer: Timer!
    private var shouldHideStatusBar = true
    private let NSNotFound: Int32 = -1
    private var lastTranslation: CGFloat = 0.0
    internal let interactor = OptionsPercentDrivenInteractiveTransition()
    
    // MARK: - Player functions
    
    func play(_ media: Media, fromURL url: URL, progress fromPosition: Float, nextEpisode: Episode? = nil, directory: URL) {
        self.url = url
        self.media = media
        self.startPosition = fromPosition
        self.nextMedia = nextEpisode
        self.directory = directory
        if let subtitles = media.subtitles {
            self.subtitles = subtitles
            currentSubtitle = media.currentSubtitle
        }
    }
    
    private func openSubtitles(_ filePath: URL) {
        if filePath.isFileURL {
            mediaplayer.addPlaybackSlave(filePath, type: .subtitle, enforce: true)
        } else {
            PopcornKit.downloadSubtitleFile(filePath.relativeString, downloadDirectory: directory, completion: { (subtitlePath, error) in
                guard let subtitlePath = subtitlePath else {return}
                self.mediaplayer.addPlaybackSlave(subtitlePath, type: .subtitle, enforce: true)
            })
        }
    }
    
    func didSelectSubtitle(_ subtitle: Subtitle?) {
        currentSubtitle = subtitle
    }
    
    private func screenshotAtTime(_ time: NSNumber, completion: @escaping (_ image: UIImage) -> Void) {
        let imageGen = AVAssetImageGenerator(asset: AVAsset(url: url))
        imageGen.appliesPreferredTrackTransform = true
        imageGen.requestedTimeToleranceAfter = kCMTimeZero
        imageGen.requestedTimeToleranceBefore = kCMTimeZero
        imageGen.cancelAllCGImageGeneration()
        imageGen.generateCGImagesAsynchronously(forTimes: [NSValue(time: CMTimeMakeWithSeconds(time.doubleValue,1000000000))]) { (_, image, _, _, error) in
            if let image = image , error == nil {
                completion(UIImage(cgImage: image))
            }
        }
    }
    
    // MARK: - View Methods
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(mediaPlayerStateChanged), name: NSNotification.Name(rawValue: VLCMediaPlayerStateChanged), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(mediaPlayerTimeChanged), name: NSNotification.Name(rawValue: VLCMediaPlayerTimeChanged), object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if startPosition > 0.0 {
            let continueWatchingAlert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            continueWatchingAlert.addAction(UIAlertAction(title: "Continue Watching", style: .default, handler:{ action in
                self.mediaplayer.play()
                self.mediaplayer.position = self.startPosition
                self.progressBar.progress = CGFloat(self.startPosition)
            }))
            continueWatchingAlert.addAction(UIAlertAction(title: "Start from beginning", style: .default, handler: { action in
                self.mediaplayer.play()
            }))
            self.present(continueWatchingAlert, animated: true, completion: nil)
            
        } else {
            mediaplayer.play()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let settings = SubtitleSettings()
        (mediaplayer as VLCFontAppearance).setTextRendererFont!(settings.fontName as NSString)
        //(mediaplayer as VLCFontAppearance).setTextRendererFontForceBold!(NSNumber(value: (style == "Bold") as Bool))
        (mediaplayer as VLCFontAppearance).setTextRendererFontSize!(NSNumber(value: settings.fontSize))
        (mediaplayer as VLCFontAppearance).setTextRendererFontColor!(NSNumber(value: settings.fontColor.hexInt()))
        mediaplayer.delegate = self
        mediaplayer.drawable = movieView
        mediaplayer.media = VLCMedia(url: url)
        progressBar.progress = 0
        mediaplayer.audio.volume = 200
        
        let siriArrowRecognizer = VLCSiriRemoteGestureRecognizer.init(target: self, action: #selector(handleSiriRemoteGesture(_:)))
        siriArrowRecognizer.delegate = self
        view.addGestureRecognizer(siriArrowRecognizer)
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
        resetIdleTimer()
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
        let type: Trakt.MediaType = media is Movie ? .movies : .episodes
        switch mediaplayer.state {
        case .error:
            fallthrough
        case .ended:
            fallthrough
        case .stopped:
            TraktManager.shared.scrobble(media.id, progress: Float(progressBar.progress), type: type, status: .finished)
            didFinishPlaying()
        case .paused:
            TraktManager.shared.scrobble(media.id, progress: Float(progressBar.progress), type: type, status: .paused)
        case .playing:
            TraktManager.shared.scrobble(media.id, progress: Float(progressBar.progress), type: type, status: .watching)
        default:
            break
        }
    }
    
    func mediaPlayerTimeChanged() {
        if loadingActivityIndicatorView.isHidden == false {
            loadingActivityIndicatorView.isHidden = true
        }
        progressBar.bufferProgress = CGFloat(PTTorrentStreamer.shared().torrentStatus.bufferingProgress)
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
//        UIView.animate(withDuration: 0.25, animations: {
//            if self.toolBarView.isHidden {
//                self.toolBarView.alpha = 1.0
//                self.navigationView.alpha = 1.0
//                self.toolBarView.isHidden = false
//                self.navigationView.isHidden = false
//            } else {
//                self.toolBarView.alpha = 0.0
//                self.navigationView.alpha = 0.0
//            }
//            }, completion: { finished in
//                if self.toolBarView.alpha == 0.0 {
//                    self.toolBarView.isHidden = true
//                    self.navigationView.isHidden = true
//                }
//        }) 
    }
    
    // MARK: - Timers
    
    func resetIdleTimer() {
        if idleTimer == nil {
            idleTimer = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(idleTimerExceeded), userInfo: nil, repeats: false)
            if !mediaplayer.isPlaying || loadingActivityIndicatorView.isHidden == false // If paused or loading, cancel timer so UI doesn't disappear
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
     
     [All colors available here]: http://www.nameacolor.com/Color%20numbers.htm
     
     - Parameter fontColor: An `NSNumber` wrapped hexInt(`UInt32`) indicating the color. Eg. Black: 0, White: 16777215, etc.
     
     - SeeAlso: [All colors available here]
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

extension UIColor {
    func hexString() -> String {
        let colorSpace = self.cgColor.colorSpace?.model
        let components = self.cgColor.components
        
        var r, g, b: CGFloat!
        
        if (colorSpace == .monochrome) {
            r = components?[0]
            g = components?[0]
            b = components?[0]
        } else if (colorSpace == .rgb) {
            r = components?[0]
            g = components?[1]
            b = components?[2]
        }
        
        return NSString(format: "#%02lX%02lX%02lX", lroundf(Float(r) * 255), lroundf(Float(g) * 255), lroundf(Float(b) * 255)) as String
    }
    
    func hexInt() -> UInt32 {
        let hex = hexString()
        var rgb: UInt32 = 0
        let s = Scanner(string: hex)
        s.scanLocation = 1
        s.scanHexInt32(&rgb)
        return rgb
    }
}
