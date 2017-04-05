

import Foundation
import PopcornTorrent
import PopcornKit

extension Media {
    
    /**
     Start playing movie or episode locally.
     
     - Parameter fromFileOrMagnetLink:  The url pointing to a .torrent file, a web adress pointing to a .torrent file to be downloaded or a magnet link.
     - Parameter nextEpisodeInSeries:   If media is an episode, pass in the next episode of the series, if applicable, for a better UX for the user.
     - Parameter loadingViewController: The view controller that will be presented while the torrent is processing to display updates to the user.
     - Parameter playViewController:    View controller to be presented to start playing the movie when loading is complete.
     - Parameter progress:              The users playback progress for the current media.
     - Parameter loadingBlock:          Block that handels updating loadingViewController UI. Defaults to updaing the progress of buffering, download speed and number of seeds.
     - Parameter playBlock:             Block that handels setting up playViewController. If playViewController is a subclass of PCTPlayerViewController, default behaviour is to call `play:fromURL:progress:directory` on playViewController.
     - Parameter errorBlock:            Block thats called when the request fails or torrent fails processing/downloading with error message parameter.
     - Parameter finishedLoadingBlock:  Block thats called when torrent is finished loading.
     */
    func play(
        fromFileOrMagnetLink url: String,
        nextEpisodeInSeries nextEpisode: Episode? = nil,
        loadingViewController: PreloadTorrentViewController,
        playViewController: UIViewController,
        progress: Float,
        loadingBlock: @escaping (PTTorrentStatus, PreloadTorrentViewController) -> Void = { (status, viewController) in
        viewController.progress = status.bufferingProgress
        viewController.speed = Int(status.downloadSpeed)
        viewController.seeds = Int(status.seeds)
        },
        playBlock: @escaping (URL, URL, Media, Episode?, Float, UIViewController) -> Void = { (videoFileURL, videoFilePath, media, nextEpisode, progress, viewController) in
        if let viewController = viewController as? PCTPlayerViewController {
            viewController.play(media, fromURL: videoFileURL, localURL: videoFilePath, progress: progress, nextEpisode: nextEpisode, directory: videoFilePath.deletingLastPathComponent())
        }
        },
        errorBlock: @escaping (String) -> Void,
        finishedLoadingBlock: @escaping (PreloadTorrentViewController, UIViewController) -> Void)
    {
        PTTorrentStreamer.shared().cancelStreamingAndDeleteData(false) // Make sure we're not already streaming
        
        if url.hasPrefix("magnet") || (url.hasSuffix(".torrent") && !url.hasPrefix("http")) {
            PTTorrentStreamer.shared().startStreaming(fromFileOrMagnetLink: url, progress: { (status) in
                loadingBlock(status, loadingViewController)
                }, readyToPlay: { (videoFileURL, videoFilePath) in
                    playBlock(videoFileURL, videoFilePath, self, nextEpisode, progress, playViewController)
                    finishedLoadingBlock(loadingViewController, playViewController)
                }, failure: { error in
                    errorBlock(error.localizedDescription)
            })
        } else {
            PopcornKit.downloadTorrentFile(url, completion: { (url, error) in
                guard !loadingViewController.shouldCancelStreaming else { return } // Make sure streaming hasn't been cancelled while torrent was downloading.
                guard let url = url, error == nil else { errorBlock(error!.localizedDescription); return }
                self.play(fromFileOrMagnetLink: url, nextEpisodeInSeries: nextEpisode, loadingViewController: loadingViewController, playViewController: playViewController, progress: progress, loadingBlock: loadingBlock, playBlock: playBlock, errorBlock: errorBlock, finishedLoadingBlock: finishedLoadingBlock)
            })
        }
    }
    
    #if os(iOS)
    
    /**
     Start playing movie or episode on chromecast.
     
     - Parameter fromFileOrMagnetLink:  The url pointing to a .torrent file, a web adress pointing to a .torrent file to be downloaded or a magnet link.
     - Parameter loadingViewController: The view controller that will be presented while the torrent is processing to display updates to the user.
     - Parameter playViewController:    View controller to be presented to handle controlling cast UI.
     - Parameter progress:              The users playback progress for the current media.
     - Parameter loadingBlock:          Block that handels updating loadingViewController UI. Defaults to updaing the progress of buffering, download speed and number of seeds.
     - Parameter playBlock:             Block that handels setting up playViewController. If playViewController is a subclass of CastPlayerViewController, default behaviour is to setup UI.
     - Parameter errorBlock:            Block thats called when the request fails or torrent fails processing/downloading with error message parameter.
     - Parameter finishedLoadingBlock:  Block thats called when torrent is finished loading.
     */
    func playOnChromecast(
        fromFileOrMagnetLink url: String,
        loadingViewController: PreloadTorrentViewController,
        playViewController: UIViewController,
        progress: Float,
        loadingBlock: @escaping ((PTTorrentStatus, PreloadTorrentViewController) -> Void) = { (status, viewController) in
        viewController.progress = status.bufferingProgress
        viewController.speed = Int(status.downloadSpeed)
        viewController.seeds = Int(status.seeds)
        },
        playBlock: @escaping (URL, URL, Media, Episode?, Float, UIViewController) -> Void = { (videoFileURL, videoFilePath, media, _, progress, viewController) in
        guard let viewController = viewController as? CastPlayerViewController, let currentSession = GCKCastContext.sharedInstance().sessionManager.currentSession else { return }
        let castMetadata: CastMetaData = (title: media.title, image: media.smallCoverImage != nil ? URL(string: media.smallCoverImage!) : nil, contentType: (media is Episode) ? "video/x-matroska" : "video/mp4", subtitles: media.subtitles, url: videoFileURL.relativeString, mediaAssetsPath: videoFilePath.deletingLastPathComponent(), startPosition: TimeInterval(progress))
        GoogleCastManager(castMetadata: castMetadata).sessionManager(GCKCastContext.sharedInstance().sessionManager, didStart: currentSession)
        viewController.media = media
        viewController.directory = videoFilePath.deletingLastPathComponent()
        },
        errorBlock: @escaping (String) -> Void,
        finishedLoadingBlock: @escaping (PreloadTorrentViewController, UIViewController) -> Void)
    {
        self.play(
            fromFileOrMagnetLink: url,
            loadingViewController: loadingViewController,
            playViewController: playViewController,
            progress: progress,
            loadingBlock: loadingBlock,
            playBlock: playBlock,
            errorBlock: errorBlock,
            finishedLoadingBlock: finishedLoadingBlock)
    }
    #endif
    
    /**
     Retrieves subtitles from OpenSubtitles
     
     - Parameter id:    The imdbId of the movie. If the media is an episode, an imdbId will be fetched automatically.
     
     - Parameter completion: The completion handler for the request containing an array of subtitles
     */
    func getSubtitles(forId id: String, completion: @escaping ([Subtitle]) -> Void) {
        if let `self` = self as? Episode, !id.hasPrefix("tt") {
            TraktManager.shared.getEpisodeMetadata(self.show.id, episodeNumber: self.episode, seasonNumber: self.season, completion: { (episode, _) in
                if let imdb = episode?.imdbId { self.getSubtitles(forId: imdb, completion: completion) } else {
                    SubtitlesManager.shared.search(self) { (subtitles, _) in
                        completion(subtitles)
                    }
                }
            })
        } else {
            SubtitlesManager.shared.search(imdbId: id) { (subtitles, _) in
                completion(subtitles)
            }
        }
    }
}
