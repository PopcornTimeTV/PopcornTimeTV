

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
        loadingViewController: LoadingViewController,
        playViewController: UIViewController,
        progress: Float,
        loadingBlock: @escaping (PTTorrentStatus, LoadingViewController) -> Void = { (status, viewController) in
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
        finishedLoadingBlock: @escaping (LoadingViewController, UIViewController) -> Void)
    {
        PTTorrentStreamer.shared().cancelStreamingAndDeleteData(false) // Make sure we're not already streaming
        
        if url.hasPrefix("magnet") || (url.hasSuffix(".torrent") && !url.hasPrefix("http")) {
            PTTorrentStreamer.shared().startStreaming(fromFileOrMagnetLink: url, progress: { (status) in
                loadingBlock(status, loadingViewController)
                }, readyToPlay: { (videoFileURL, videoFilePath) in
                    playBlock(videoFileURL, videoFilePath, self, nextEpisode, progress, playViewController)
                    finishedLoadingBlock(loadingViewController, playViewController)
                }, failure: { _ in
                    errorBlock("Error processing torrent.")
            })
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
        loadingViewController: LoadingViewController,
        playViewController: UIViewController,
        progress: Float,
        loadingBlock: @escaping ((PTTorrentStatus, LoadingViewController) -> Void) = { (status, viewController) in
        viewController.progress = status.bufferingProgress
        viewController.speed = Int(status.downloadSpeed)
        viewController.seeds = Int(status.seeds)
        },
        playBlock: @escaping (URL, URL, Media, Episode?, Float, UIViewController) -> Void = { (videoFileURL, videoFilePath, media, _, progress, viewController) in
        guard let viewController = viewController as? CastPlayerViewController else { return }
        let castMetadata: CastMetaData = (title: media.title, image: media.smallCoverImage != nil ? URL(string: media.smallCoverImage!) : nil, contentType: (media is Episode) ? "video/x-matroska" : "video/mp4", subtitles: media.subtitles, url: videoFileURL.relativeString, mediaAssetsPath: videoFilePath.deletingLastPathComponent())
        GoogleCastManager(castMetadata: castMetadata).sessionManager(GCKCastContext.sharedInstance().sessionManager, didStart: GCKCastContext.sharedInstance().sessionManager.currentSession!)
        viewController.title = media.title
        viewController.media = media
        viewController.startPosition = TimeInterval(progress)
        viewController.directory = videoFilePath.deletingLastPathComponent()
        },
        errorBlock: @escaping (String) -> Void,
        finishedLoadingBlock: @escaping (LoadingViewController, UIViewController) -> Void)
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
}
