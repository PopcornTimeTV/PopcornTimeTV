

import UIKit
import PopcornTorrent
import GoogleCast
import PopcornKit
import GCDWebServer

class CastPlayerViewController: UIViewController, GCKRemoteMediaClientListener, GCKRequestDelegate {
    
    @IBOutlet var progressSlider: ProgressSlider!
    @IBOutlet var volumeSlider: UISlider!
    @IBOutlet var closeButton: BlurButton!
    @IBOutlet var subtitleButton: UIButton!
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var backgroundImageView: UIImageView!
    @IBOutlet var elapsedTimeLabel: UILabel!
    @IBOutlet var remainingTimeLabel: UILabel!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var playPauseButton: UIButton!
    @IBOutlet var compactConstraints: [NSLayoutConstraint] = []
    @IBOutlet var regularConstraints: [NSLayoutConstraint] = []
    
    private var elapsedTimer: Timer!
    
    var media: Media!
    var directory: URL!
    var url: URL!
    var streamer: PTTorrentStreamer!
    var localPathToMedia: URL!
    var startPosition: TimeInterval = 0.0
    var currentSubtitle: Subtitle? {
        didSet {
            guard oldValue != currentSubtitle else { return }
            
            let request: GCKRequest?
            
            if let subtitle = currentSubtitle,
                let index = media.subtitles.index(of: subtitle) {
                request = remoteMediaClient?.setActiveTrackIDs([NSNumber(value: index)])
            } else {
                request = remoteMediaClient?.setActiveTrackIDs(nil)
            }
            
            request?.delegate = self
            request?.customData = true // Destinguish between subtitle delegate and other delegate calls.
        }
    }
    let server: GCDWebServer = GCDWebServer()
    
    private var remoteMediaClient: GCKRemoteMediaClient? {
        return GCKCastContext.sharedInstance().sessionManager.currentCastSession?.remoteMediaClient
    }
    
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
    
    // MARK: - IBActions
    
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
    
    @IBAction func volumeSliderAction() {
        remoteMediaClient?.setStreamVolume(volumeSlider.value)
    }
    
    @IBAction func progressSliderAction() {
        streamPosition = (TimeInterval(progressSlider.value) * streamDuration)
    }
    
    @IBAction func progressSliderDrag() {
        remoteMediaClient?.pause()
        elapsedTimeLabel.text = VLCTime(number: NSNumber(value: ((TimeInterval(progressSlider.value) * streamDuration)) * 1000)).stringValue
        remainingTimeLabel.text = VLCTime(number: NSNumber(value: (((TimeInterval(progressSlider.value) * streamDuration) - streamDuration)) * 1000)).stringValue
    }
    
    @IBAction func close() {
        elapsedTimer?.invalidate()
        elapsedTimer = nil
        remoteMediaClient?.stop()
        setProgress(status: .finished)
        streamer.cancelStreamingAndDeleteData(UserDefaults.standard.bool(forKey: "removeCacheOnPlayerExit"))
        dismiss(animated: true)
    }
    
    // MARK: - Frame changes
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        for constraint in compactConstraints {
            constraint.priority = traitCollection.horizontalSizeClass == .compact ? 999 : traitCollection.horizontalSizeClass == .regular && traitCollection.verticalSizeClass == .regular ? 240 : constraint.priority
        }
        for constraint in regularConstraints {
            constraint.priority = traitCollection.horizontalSizeClass == .compact ? 240 : traitCollection.horizontalSizeClass == .regular && traitCollection.verticalSizeClass == .regular ? 999 : constraint.priority
        }
        
        if previousTraitCollection != nil {
            UIView.animate(withDuration: .default) {
                self.view.layoutIfNeeded()
            }
        }
    }
    
    // MARK: - Player changes notifications
    
    func setProgress(status: Trakt.WatchedStatus) {
        if let movie = media as? Movie {
            WatchedlistManager<Movie>.movie.setCurrentProgress(progressSlider.value, for: movie.id, with: status)
        } else if let episode = media as? Episode {
            WatchedlistManager<Episode>.episode.setCurrentProgress(progressSlider.value, for: episode.id, with: status)
        }
    }
    
    func updateTime() {
        progressSlider?.value = Float(streamPosition/streamDuration)
        remainingTimeLabel?.text = remainingTime.stringValue
        elapsedTimeLabel?.text = elapsedTime.stringValue
    }
    
    func remoteMediaClient(_ client: GCKRemoteMediaClient, didUpdate mediaStatus: GCKMediaStatus?) {
        guard let mediaStatus = mediaStatus else { return }
        
        volumeSlider?.setValue(mediaStatus.volume, animated: true)
        
        switch mediaStatus.playerState {
        case .paused:
            setProgress(status: .paused)
            playPauseButton.setImage(UIImage(named: "Play"), for: .normal)
            elapsedTimer?.invalidate()
            elapsedTimer = nil
        case .playing:
            setProgress(status: .watching)
            playPauseButton.setImage(UIImage(named: "Pause"), for: .normal)
            if elapsedTimer == nil {
                elapsedTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateTime), userInfo: nil, repeats: true)
            }
        case .buffering:
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
    
    @IBAction func chooseSubtitle(_ sender: UIButton) {
        let alertController = UIAlertController(title: "Subtitle Language".localized, message: nil, preferredStyle: .actionSheet, blurStyle: .dark)
        
        alertController.addAction(UIAlertAction(title: "None".localized, style: .default) { [unowned self] _ in
            self.currentSubtitle = nil
        })
        alertController.addAction(UIAlertAction(title: "Cancel".localized, style: .cancel, handler: nil))
        
        
        for subtitle in media.subtitles {
            alertController.addAction(UIAlertAction(title: subtitle.language, style: .default) { [unowned self] _ in
                self.currentSubtitle = subtitle
            })
        }
        
        alertController.preferredAction = alertController.actions.first(where: { $0.title == currentSubtitle?.language }) ?? alertController.actions.first(where: { $0.title == "None".localized })
        
        alertController.popoverPresentationController?.sourceView = sender
        
        present(alertController, animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        server.addDefaultHandler(forMethod: "GET", request: GCDWebServerRequest.self) { [weak self] (request, completion) in
            guard
                let `self` = self,
                let path = request?.path,
                let subtitle = self.media.subtitles.first(where: {$0.ISO639 == request?.url.lastPathComponent.replacingOccurrences(of: ".vtt", with: "")})
            else {
                let response = GCDWebServerFileResponse(statusCode: 204)
                completion?(response)
                return
            }
            
            let completion: (GCDWebServerResponse) -> () = { response in
                response.setValue("*", forAdditionalHeader: "Access-Control-Allow-Origin")
                response.setValue("public", forAdditionalHeader: "Cache-Control")
                response.setValue("Content-Type", forAdditionalHeader: "Access-Control-Expose-Headers")
                
                completion?(response)
            }
                
                
            if let url = self.directory?.appendingPathComponent(path),
                FileManager.default.fileExists(atPath: url.path)
            {
                let response: GCDWebServerFileResponse = GCDWebServerFileResponse(file: url.relativePath)
                completion(response)
            } else {
                let link = subtitle.link.replacingOccurrences(of: "/download/", with: "/download/subformat-vtt/") // Google cast only supports web vtt
                
                PopcornKit.downloadSubtitleFile(link, fileName: "\(subtitle.ISO639).vtt", downloadDirectory: self.directory) { (url, error) in
                    let response: GCDWebServerFileResponse
                    
                    if let url = url {
                        response = GCDWebServerFileResponse(file: url.relativePath)
                    } else {
                        response = GCDWebServerFileResponse(statusCode: error?.code ?? 204)
                    }
                    
                    completion(response)
                }
            }
        }
        
        server.start(withPort: 60692, bonjourName: nil)
        
        let metadata = media is Movie ? GCKMediaMetadata(metadataType: .movie) : GCKMediaMetadata(metadataType: .tvShow)
        
        metadata.setString(media.title, forKey: kGCKMetadataKeyTitle)
        if let image = media.smallCoverImage, let url = URL(string: image) {
            metadata.addImage(GCKImage(url: url, width: 480, height: 720))
        }
        
        let mediaTracks: [GCKMediaTrack] = media.subtitles.flatMap {
            let index = media.subtitles.index(of: $0)!
            let track = GCKMediaTrack(identifier: index, contentIdentifier: "\(server.serverURL.relativeString)/Subtitles/\($0.ISO639).vtt", contentType: "text/vtt", type: .text, textSubtype: .captions, name: $0.language, languageCode: $0.ISO639, customData: nil)
            return track
        }
        
        
        let mediaInfo = GCKMediaInformation(contentID: url.relativeString, streamType: .buffered, contentType: localPathToMedia.contentType, metadata: metadata, streamDuration: 0, mediaTracks: mediaTracks.isEmpty ? nil : mediaTracks, textTrackStyle: .default, customData: nil)
        
        let activeTrackIDs: [NSNumber]? = SubtitleSettings.shared.language.flatMap { preferredLanguage in
            return media.subtitles.index(where: {$0.language == preferredLanguage})
        }.flatMap{ [NSNumber(value: $0)] }
        
        remoteMediaClient?.loadMedia(mediaInfo, autoplay: true, playPosition: startPosition, activeTrackIDs: activeTrackIDs).delegate = self
        
        subtitleButton.isHidden = media.subtitles.isEmpty
    
        titleLabel.text = media.title
        volumeSlider.setThumbImage(UIImage(named: "Scrubber Image"), for: .normal)
        
        elapsedTimer = elapsedTimer ?? Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateTime), userInfo: nil, repeats: true)
        
        if let image = media.largeCoverImage, let url = URL(string: image) {
            imageView.af_setImage(withURL: url)
            backgroundImageView.af_setImage(withURL: url)
        }
    }
    
    func request(_ request: GCKRequest, didFailWithError error: GCKError) {
        if let isSubtitle = request.customData as? Bool, isSubtitle {
            currentSubtitle = nil
        } else {
            close()
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        remoteMediaClient?.add(self)
        UIApplication.shared.isIdleTimerDisabled = true
    }
    
    deinit {
        remoteMediaClient?.remove(self)
        server.isRunning ? server.stop() : ()
        UIApplication.shared.isIdleTimerDisabled = false
    }
    
    override var shouldAutorotate: Bool {
        return UIDevice.current.userInterfaceIdiom == .pad
    }
}
