

import Foundation
import PopcornTorrent
import PopcornKit

extension Media {
    
    /**
     Start playing movie or episode locally.
     
     - Parameter loadingViewController: The view controller that will be presented while the torrent is processing to display updates to the user.
     - Parameter playViewController:    View controller to be presented to start playing the movie when loading is complete.
     - Parameter loadingBlock:          Block that handels updating loadingViewController UI. Defaults to updaing the progress of buffering, download speed and number of seeds.
     - Parameter playBlock:             Block that handels setting up playViewController. If playViewController is a subclass of PCTPlayerViewController, default behaviour is to call `play:fromURL:progress:directory` on playViewController.
     - Parameter errorBlock:            Block thats called when the request fails or torrent fails processing/downloading with error message parameter.
     - Parameter finishedLoadingBlock:  Block thats called when torrent is finished loading.
     */
    func play(
        fromFileOrMagnetLink url: String,
        loadingViewController: LoadingViewController,
        playViewController: UIViewController,
        progress: Float,
        loadingBlock: @escaping (PTTorrentStatus, LoadingViewController) -> Void = { (status, viewController) in
        viewController.progress = status.bufferingProgress
        viewController.speed = Int(status.downloadSpeed)
        viewController.seeds = Int(status.seeds)
        },
        playBlock: @escaping (URL, URL, Media, Float, UIViewController) -> Void = { (videoFileURL, videoFilePath, media, progress, viewController) in
        if let viewController = viewController as? PCTPlayerViewController {
            viewController.play(media, fromURL: videoFileURL, progress: progress, directory: videoFilePath.deletingLastPathComponent())
        }
        },
        errorBlock: @escaping (String) -> Void,
        finishedLoadingBlock: @escaping (LoadingViewController, UIViewController) -> Void)
    {
        if !url.hasPrefix("magnet") {
            PopcornKit.downloadTorrentFile(url, completion: { (url, error) in
                guard let url = url, error == nil else { errorBlock(error!.localizedDescription); return }
                self.play(fromFileOrMagnetLink: url, loadingViewController: loadingViewController, playViewController: playViewController, progress: progress, loadingBlock: loadingBlock, playBlock: playBlock, errorBlock: errorBlock, finishedLoadingBlock: finishedLoadingBlock)
            })
        } else {
            PTTorrentStreamer.shared().startStreaming(fromFileOrMagnetLink: url, progress: { (status) in
                loadingBlock(status, loadingViewController)
                }, readyToPlay: { (videoFileURL, videoFilePath) in
                    playBlock(videoFileURL, videoFilePath, self, progress, playViewController)
                    finishedLoadingBlock(loadingViewController, playViewController)
                }, failure: { _ in
                    errorBlock("Error processing torrent.")
            })
        }
    }
}
