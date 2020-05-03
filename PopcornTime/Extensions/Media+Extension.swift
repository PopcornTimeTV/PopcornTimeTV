

import Foundation
import PopcornTorrent
import PopcornKit
import MediaPlayer.MPMediaItem

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
        playBlock: @escaping (URL, URL, Media, Episode?, Float, UIViewController, PTTorrentStreamer) -> Void = { (videoFileURL, videoFilePath, media, nextEpisode, progress, viewController, streamer) in
        if let viewController = viewController as? PCTPlayerViewController {
            viewController.play(media, fromURL: videoFileURL, localURL: videoFilePath, progress: progress, nextEpisode: nextEpisode, directory: videoFilePath.deletingLastPathComponent(), streamer: streamer)
        }
        },
        errorBlock: @escaping (String) -> Void,
        finishedLoadingBlock: @escaping (PreloadTorrentViewController, UIViewController) -> Void,
        selectingTorrentBlock: ( (Array<String>) -> Int32)? = nil)
    {
        if hasDownloaded, let download = associatedDownload {
            return download.play { (videoFileURL, videoFilePath) in
                loadingViewController.streamer = download
                playBlock(videoFileURL, videoFilePath, self, nextEpisode, progress, playViewController, download)
                finishedLoadingBlock(loadingViewController, playViewController)
            }
        }

        PTTorrentStreamer.shared().cancelStreamingAndDeleteData(false) // Make sure we're not already streaming

        if url.hasPrefix("magnet") || (url.hasSuffix(".torrent") && !url.hasPrefix("http")) {
            loadingViewController.streamer = .shared()
            if selectingTorrentBlock != nil {
                PTTorrentStreamer.shared().startStreaming(fromMultiTorrentFileOrMagnetLink: url, progress: { (status) in
                    loadingBlock(status, loadingViewController)
                }, readyToPlay: { (videoFileURL, videoFilePath) in
                    playBlock(videoFileURL, videoFilePath, self, nextEpisode, progress, playViewController, .shared())
                    finishedLoadingBlock(loadingViewController, playViewController)
                }, failure: { error in
                    errorBlock(error.localizedDescription)
                }, selectFileToStream: { torrents in
                    return selectingTorrentBlock!(torrents)
                })
            }else{
                PTTorrentStreamer.shared().startStreaming(fromFileOrMagnetLink: url, progress: { (status) in
                    loadingBlock(status, loadingViewController)
                }, readyToPlay: { (videoFileURL, videoFilePath) in
                    playBlock(videoFileURL, videoFilePath, self, nextEpisode, progress, playViewController, .shared())
                    finishedLoadingBlock(loadingViewController, playViewController)
                }, failure: { error in
                    errorBlock(error.localizedDescription)
                })
            }
        } else {
            PopcornKit.downloadTorrentFile(url, completion: { (url, error) in
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
        playBlock: @escaping (URL, URL, Media, Episode?, Float, UIViewController, PTTorrentStreamer) -> Void = { (videoFileURL, videoFilePath, media, _, progress, viewController, streamer) in
        guard let viewController = viewController as? CastPlayerViewController else { return }
        viewController.media = media
        viewController.url = videoFileURL
        viewController.streamer = streamer
        viewController.localPathToMedia = videoFilePath
        viewController.directory = videoFilePath.deletingLastPathComponent()
        viewController.startPosition = TimeInterval(progress)
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

     - Parameter id:    `nil` by default. The imdb id of the media will be used by default.

     - Parameter completion: The completion handler for the request containing an array of subtitles
     */
    func getSubtitles(forId id: String? = nil, orWithFilePath: URL? = nil, forLang:String? = nil,completion: @escaping (Dictionary<String, [Subtitle]>) -> Void) {
        let id = id ?? self.id
//        if let filePath = orWithFilePath {
//            SubtitlesManager.shared.search(preferredLang: "el", videoFilePath: filePath){ (subtitles, _) in
//                completion(subtitles)
//            }
//        } else if let `self` = self as? Episode, !id.hasPrefix("tt"), let show = self.show {
        if let `self` = self as? Episode, !id.hasPrefix("tt"), let show = self.show {
            TraktManager.shared.getEpisodeMetadata(show.id, episodeNumber: self.episode, seasonNumber: self.season) { (episode, _) in
                if let imdb = episode?.imdbId { return self.getSubtitles(forId: imdb, completion: completion) }

                SubtitlesManager.shared.search(self) { (subtitles, _) in
                    completion(subtitles)
                }
            }
        } else if let filePath = orWithFilePath {
          SubtitlesManager.shared.search(videoFilePath: filePath){ (subtitles, _) in
                              completion(subtitles)
            }} else {
            SubtitlesManager.shared.search(imdbId: id) { (subtitles, _) in
                completion(subtitles)
            }
        }
    }

    /// The download, either completed or downloading, that is associated with this media object.
    var associatedDownload: PTTorrentDownload? {
        let array = PTTorrentDownloadManager.shared().activeDownloads + PTTorrentDownloadManager.shared().completedDownloads
        return array.first(where: {($0.mediaMetadata[MPMediaItemPropertyPersistentID] as? String) == self.id})
    }


    /// Boolean value indicating whether the media is currently downloading.
    var isDownloading: Bool {
        return PTTorrentDownloadManager.shared().activeDownloads.first(where: {($0.mediaMetadata[MPMediaItemPropertyPersistentID] as? String) == self.id}) != nil
    }

    /// Boolean value indicating whether the media has been downloaded.
    var hasDownloaded: Bool {
        return PTTorrentDownloadManager.shared().completedDownloads.first(where: {($0.mediaMetadata[MPMediaItemPropertyPersistentID] as? String) == self.id}) != nil
    }
}
