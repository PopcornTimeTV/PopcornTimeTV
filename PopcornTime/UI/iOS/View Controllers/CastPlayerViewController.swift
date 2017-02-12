

import UIKit
import PopcornTorrent
import GoogleCast
import SwiftyTimer
import PopcornKit


class CastPlayerViewController: UIViewController, GCKRemoteMediaClientListener {
    
    @IBOutlet var progressSlider: ProgressSlider!
    @IBOutlet var volumeSlider: UISlider!
    @IBOutlet var closeButton: BlurButton!
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var backgroundImageView: UIImageView!
    @IBOutlet var elapsedTimeLabel: UILabel!
    @IBOutlet var remainingTimeLabel: UILabel!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var playPauseButton: UIButton!
    @IBOutlet var compactConstraints: [NSLayoutConstraint]!
    @IBOutlet var regularConstraints: [NSLayoutConstraint]!
    
    private var classContext = 0
    private var elapsedTimer: Timer!
    private var observingValues: Bool = false
    
    var startPosition: TimeInterval = 0.0
    var media: Media!
    var directory: URL!
    
    private var remoteMediaClient = GCKCastContext.sharedInstance().sessionManager.currentCastSession?.remoteMediaClient
    private var timeSinceLastMediaStatusUpdate: TimeInterval {
        if let remoteMediaClient = remoteMediaClient, state == .playing {
            return remoteMediaClient.timeSinceLastMediaStatusUpdate
        }
        return 0.0
    }
    private var streamPosition: TimeInterval {
        get {
            if let mediaStatus = remoteMediaClient?.mediaStatus {
                return mediaStatus.streamPosition + timeSinceLastMediaStatusUpdate
            }
            return 0.0
        } set {
            remoteMediaClient?.seek(toTimeInterval: newValue, resumeState: GCKMediaResumeState.play)
        }
    }
    private var state: GCKMediaPlayerState {
        return remoteMediaClient?.mediaStatus?.playerState ?? GCKMediaPlayerState.unknown
    }
    private var idleReason: GCKMediaPlayerIdleReason {
        return remoteMediaClient?.mediaStatus?.idleReason ?? GCKMediaPlayerIdleReason.none
    }
    private var streamDuration: TimeInterval {
        return remoteMediaClient?.mediaStatus?.mediaInformation?.streamDuration ?? 0.0
    }
    private var elapsedTime: VLCTime {
        return VLCTime(number: NSNumber(value: streamPosition * 1000 as Double))
    }
    private var remainingTime: VLCTime {
        return VLCTime(number: NSNumber(value: (streamPosition - streamDuration) * 1000 as Double))
    }
    
    @IBAction func playPause(_ sender: UIButton) {
        if state == .paused {
            remoteMediaClient?.play()
        } else if state == .playing {
            remoteMediaClient?.pause()
        }
    }
    
    @IBAction func rewind() {
        streamPosition -= 30
    }
    
    @IBAction func fastForward() {
        streamPosition += 30
    }
    
    @IBAction func subtitles(_ sender: UIButton) {
    }
    
    @IBAction func volumeSliderAction() {
        remoteMediaClient?.setStreamVolume(volumeSlider.value)
    }
    
    @IBAction func progressSliderAction() {
        streamPosition += (TimeInterval(progressSlider.value) * streamDuration)
    }
    
    @IBAction func progressSliderDrag() {
        remoteMediaClient?.pause()
        elapsedTimeLabel.text = VLCTime(number: NSNumber(value: ((TimeInterval(progressSlider.value) * streamDuration)) * 1000 as Double)).stringValue
        remainingTimeLabel.text = VLCTime(number: NSNumber(value: (((TimeInterval(progressSlider.value) * streamDuration) - streamDuration)) * 1000 as Double)).stringValue
    }
    
    @IBAction func close() {
        if observingValues {
            do { try remoteMediaClient?.mediaStatus?.removeObserver(self, forKeyPath: "playerState") }
            observingValues = false
        }
        elapsedTimer?.invalidate()
        elapsedTimer = nil
        remoteMediaClient?.stop()
        PTTorrentStreamer.shared().cancelStreamingAndDeleteData(UserDefaults.standard.bool(forKey: "removeCacheOnPlayerExit"))
        dismiss(animated: true, completion: nil)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        for constraint in compactConstraints {
            constraint.priority = traitCollection.horizontalSizeClass == .compact ? 999 : traitCollection.horizontalSizeClass == .regular && traitCollection.verticalSizeClass == .regular ? 240 : constraint.priority
        }
        for constraint in regularConstraints {
            constraint.priority = traitCollection.horizontalSizeClass == .compact ? 240 : traitCollection.horizontalSizeClass == .regular && traitCollection.verticalSizeClass == .regular ? 999 : constraint.priority
        }
        UIView.animate(withDuration: animationLength, animations: {
            self.view.layoutIfNeeded()
        })
    }
    
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if context == &classContext, let newValue = change?[.newKey] {
            if keyPath == "playerState", let raw = newValue as? Int, let state = GCKMediaPlayerState(rawValue: raw) {
                switch state {
                case .paused:
                    UIApplication.shared.isIdleTimerDisabled = false
                    setProgress(status: .paused)
                    playPauseButton.setImage(UIImage(named: "Play"), for: .normal)
                    elapsedTimer.invalidate()
                    elapsedTimer = nil
                case .playing:
                    UIApplication.shared.isIdleTimerDisabled = true
                    setProgress(status: .watching)
                    playPauseButton.setImage(UIImage(named: "Pause"), for: .normal)
                    if elapsedTimer == nil {
                        elapsedTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateTime), userInfo: nil, repeats: true)
                    }
                case .buffering:
                    UIApplication.shared.isIdleTimerDisabled = true
                    playPauseButton.setImage(UIImage(named: "Play"), for: .normal)
                case .idle:
                    switch idleReason {
                    case .none:
                        break
                    default:
                        setProgress(status: .finished)
                        close()
                    }
                default:
                    break
                }
            }
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
    
    func setProgress(status: Trakt.WatchedStatus) {
        if let movie = media as? Movie {
            WatchedlistManager<Movie>.movie.setCurrentProgress(progressSlider.value, forId: movie.id, withStatus: status)
        } else if let episode = media as? Episode {
            WatchedlistManager<Episode>.episode.setCurrentProgress(progressSlider.value, forId: episode.id, withStatus: status)
        }
    }
    
    func updateTime() {
        progressSlider.value = Float(streamPosition/streamDuration)
        remainingTimeLabel.text = remainingTime.stringValue
        elapsedTimeLabel.text = elapsedTime.stringValue
    }
    
    func remoteMediaClient(_ client: GCKRemoteMediaClient, didUpdate mediaStatus: GCKMediaStatus) {
        if !observingValues {
            if let subtitle = media.currentSubtitle {
                remoteMediaClient?.setActiveTrackIDs([NSNumber(value: media.subtitles.index{$0.link == subtitle.link}! as Int)])
            }
            elapsedTimer = elapsedTimer ?? Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateTime), userInfo: nil, repeats: true)
            mediaStatus.addObserver(self, forKeyPath: "playerState", options: .new, context: &classContext)
            observingValues = true
            streamPosition = startPosition * streamDuration
            volumeSlider?.setValue(mediaStatus.volume, animated: true)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        remoteMediaClient?.add(self)
        UIApplication.shared.isIdleTimerDisabled = true
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        if let image = media.largeCoverImage, let url = URL(string: image) {
            imageView.af_setImage(withURL: url)
            backgroundImageView.af_setImage(withURL: url)
        } 
        titleLabel.text = media.title
        volumeSlider.setThumbImage(UIImage(named: "Scrubber Image"), for: .normal)
    }
    
    deinit {
        UIApplication.shared.isIdleTimerDisabled = false
    }
    
    override var shouldAutorotate : Bool {
        return UIDevice.current.userInterfaceIdiom == .pad
    }
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return .lightContent
    }
}
