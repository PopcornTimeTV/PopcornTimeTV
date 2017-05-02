

import Foundation
import MediaPlayer
import AlamofireImage

extension PCTPlayerViewController {
    
    func addRemoteCommandCenterHandlers() {
        
        let center = MPRemoteCommandCenter.shared()
            
        center.pauseCommand.addTarget { (event) -> MPRemoteCommandHandlerStatus in
            self.playandPause()
            return self.mediaplayer.state == .paused ? .success : .commandFailed
        }
        
        center.playCommand.addTarget { (event) -> MPRemoteCommandHandlerStatus in
            self.playandPause()
            return self.mediaplayer.state == .playing ? .success : .commandFailed
        }
        
        if #available(iOS 9.1, tvOS 9.1, *) {
            center.changePlaybackPositionCommand.addTarget { (event) -> MPRemoteCommandHandlerStatus in
                self.mediaplayer.time = VLCTime(number: NSNumber(value: (event as! MPChangePlaybackPositionCommandEvent).positionTime * 1000))
                return .success
            }
        }
        
        center.stopCommand.addTarget { (event) -> MPRemoteCommandHandlerStatus in
            self.mediaplayer.stop()
            return .success
        }
        
        center.changePlaybackRateCommand.addTarget { (event) -> MPRemoteCommandHandlerStatus in
            self.mediaplayer.rate = (event as! MPChangePlaybackRateCommandEvent).playbackRate
            return .success
        }
        
        center.skipForwardCommand.addTarget { (event) -> MPRemoteCommandHandlerStatus in
            self.mediaplayer.jumpForward(Int32((event as! MPSkipIntervalCommandEvent).interval))
            return .success
        }
        
        center.skipBackwardCommand.addTarget { (event) -> MPRemoteCommandHandlerStatus in
            self.mediaplayer.jumpBackward(Int32((event as! MPSkipIntervalCommandEvent).interval))
            return .success
        }
    }
    
    func removeRemoteCommandCenterHandlers() {
        nowPlayingInfo = nil
        UIApplication.shared.endReceivingRemoteControlEvents()
    }
    
    func configureNowPlayingInfo() {
        nowPlayingInfo = [MPMediaItemPropertyTitle: media.title,
                          MPMediaItemPropertyPlaybackDuration: TimeInterval(streamDuration/1000),
                          MPNowPlayingInfoPropertyElapsedPlaybackTime: mediaplayer.time.value.doubleValue/1000,
                          MPNowPlayingInfoPropertyPlaybackRate: Double(mediaplayer.rate),
                          MPMediaItemPropertyMediaType: 256] // `MPMediaType` enum not available in tvOS for some reason so raw value used instead.
        
        if let image = media.mediumCoverImage ?? media.mediumCoverImage, let request = try? URLRequest(url: image, method: .get) {
            ImageDownloader.default.download(request) { (response) in
                guard let image = response.result.value else { return }
                if #available(iOS 10.0, tvOS 10.0, *) {
                    self.nowPlayingInfo?[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: image.size) { (_) -> UIImage in
                        return image
                    }
                } else {
                    self.nowPlayingInfo?[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(image: image)
                }
            }
        }
    }
    
    override func remoteControlReceived(with event: UIEvent?) {
        guard let event = event else { return }
        
        switch event.subtype {
            case .remoteControlPlay:
                fallthrough
            case .remoteControlPause:
                fallthrough
            case .remoteControlTogglePlayPause:
                playandPause()
            case .remoteControlStop:
                mediaplayer.stop()
            default:
                break
        }
    }
}
