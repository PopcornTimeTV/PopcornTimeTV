

import Foundation
import PopcornKit
import PopcornTorrent.PTTorrentStreamer
import MediaPlayer.MPMediaItem

extension AppDelegate: PCTPlayerViewControllerDelegate, UIViewControllerTransitioningDelegate {
    
    func chooseQuality(_ sender: UIView?, media: Media, completion: @escaping (Torrent) -> Void) {
        if let quality = UserDefaults.standard.string(forKey: "autoSelectQuality") {
            let sorted  = media.torrents.sorted(by: <)
            let torrent = quality == "Highest".localized ? sorted.last! : sorted.first!
            
            return completion(torrent)
        }
        
        guard media.torrents.count > 1 else {
            if let torrent = media.torrents.first {
                completion(torrent)
            } else {
                let alertController = UIAlertController(title: "No torrents found".localized, message: "Torrents could not be found for the specified media.".localized, preferredStyle: .alert)
                alertController.addAction(UIAlertAction(title: "OK".localized, style: .default, handler: nil))
                alertController.show(animated: true)
            }
            return
        }
        
        let style: UIAlertController.Style = sender == nil ? .alert : .actionSheet
        let blurStyle: UIBlurEffect.Style  = style == .alert ? .extraLight : .dark
        let alertController = UIAlertController(title: "Choose Quality".localized, message: nil, preferredStyle: style, blurStyle: blurStyle)
        
        for torrent in media.torrents {
            let action = UIAlertAction(title: torrent.quality, style: .default) { _ in
                completion(torrent)
            }
            action.setValue(torrent.health.image.withRenderingMode(.alwaysOriginal), forKey: "image")
            alertController.addAction(action)
        }
        
        alertController.addAction(UIAlertAction(title: "Cancel".localized, style: .cancel, handler: nil))
        
        alertController.popoverPresentationController?.sourceView = sender
        present(alertController, animated:true, completion: nil)
    }
    
    func play(_ media: Media, torrent: Torrent) {
        if UIDevice.current.hasCellularCapabilites && !reachability.isReachableViaWiFi() && !UserDefaults.standard.bool(forKey: "streamOnCellular")  {
            
            let alertController = UIAlertController(title: "Cellular Data is turned off for streaming".localized, message: nil, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "Turn On".localized, style: .default) { [unowned self] _ in
                UserDefaults.standard.set(true, forKey: "streamOnCellular")
                self.play(media, torrent: torrent)
            })
            alertController.addAction(UIAlertAction(title: "Cancel".localized, style: .cancel, handler: nil))
            return alertController.show(animated: true)
        }
        
        let storyboard = UIStoryboard.main
        var media = media
        
        let currentProgress = media is Movie ? WatchedlistManager<Movie>.movie.currentProgress(media.id) : WatchedlistManager<Episode>.episode.currentProgress(media.id)
        var nextEpisode: Episode?
        
        let loadingViewController = storyboard.instantiateViewController(withIdentifier: "PreloadTorrentViewController") as! PreloadTorrentViewController
        loadingViewController.transitioningDelegate = self
        loadingViewController.loadView()
        
        let backgroundImage: String?
        
        if let episode = media as? Episode, let show = episode.show {
            backgroundImage = show.largeBackgroundImage
            var episodesLeftInShow = [Episode]()
            
            for season in show.seasonNumbers where season >= episode.season {
                episodesLeftInShow += show.episodes.filter({$0.season == season}).sorted(by: {$0.episode < $1.episode})
            }
            
            if let index = episodesLeftInShow.firstIndex(of: episode) {
                episodesLeftInShow.removeFirst(index + 1)
            }
            
            nextEpisode = !episodesLeftInShow.isEmpty ? episodesLeftInShow.removeFirst() : nil
            nextEpisode?.show = episode.show
        } else {
            backgroundImage = media.largeBackgroundImage
        }
        
        if let image = backgroundImage, let url = URL(string: image) {
            loadingViewController.backgroundImageView?.af_setImage(withURL: url)
        }
        loadingViewController.titleLabel.text = media.title
        
        present(loadingViewController, animated: true)
        
        let error: (String) -> Void = { (errorMessage) in
            let alertController = UIAlertController(title: "Error".localized, message: errorMessage, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "OK".localized, style: .cancel, handler: { _ in
                self.dismiss(animated: true, completion: nil)
            }))
            alertController.show(animated: true)
        }
        
        UIApplication.shared.isIdleTimerDisabled = true
        let finishedLoading: (PreloadTorrentViewController, UIViewController) -> Void = { (loadingVc, playerVc) in
            // Enable here, so playerVc behavior is unchanged.
            UIApplication.shared.isIdleTimerDisabled = false
            let flag = UIDevice.current.userInterfaceIdiom != .tv
            self.dismiss(animated: flag) {
                self.present(playerVc, animated: flag)
            }
        }
        
        let selectTorrent: (Array<String>) -> Int32 = { (torrents) in
            var selected:Int32! = -1
            let torrentSelection = UIAlertController(title: "Select file to play", message: nil, preferredStyle: .alert)
            for torrent in torrents{
                torrentSelection.addAction(UIAlertAction(title: torrent, style: .default, handler: { _ in
                    selected = Int32(torrents.firstIndex(of:torrent) ?? -1)
                }))
            }
            DispatchQueue.main.sync{
                torrentSelection.show(animated: true)
            }

            while selected == -1{ print("hold")}
            return selected
        }
        
        media.getSubtitles { [unowned self] subtitles in
            guard self.window?.rootViewController?.presentedViewController === loadingViewController else { return } // Make sure the user is still loading.
            
            media.subtitles = subtitles
            #if os(iOS)
                
            if GCKCastContext.sharedInstance().castState == .connected {
                let playViewController = storyboard.instantiateViewController(withIdentifier: "CastPlayerViewController") as! CastPlayerViewController
                media.playOnChromecast(fromFileOrMagnetLink: torrent.url, loadingViewController: loadingViewController, playViewController: playViewController, progress: currentProgress, errorBlock: error, finishedLoadingBlock: finishedLoading)
                return
            }
            #endif
                
            let playViewController = storyboard.instantiateViewController(withIdentifier: "PCTPlayerViewController") as! PCTPlayerViewController
            playViewController.delegate = self
            media.play(fromFileOrMagnetLink: torrent.url, nextEpisodeInSeries: nextEpisode, loadingViewController: loadingViewController, playViewController: playViewController, progress: currentProgress, errorBlock: error, finishedLoadingBlock: finishedLoading, selectingTorrentBlock: media.title == "Unknown" ? selectTorrent : nil)
        }
    }
    
    func downloadButton(_ button: DownloadButton, wasPressedWith download: PTTorrentDownload, didDeleteHandler: (() -> Void)? = nil) {
        switch button.downloadState {
        case .downloaded:
            let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet, blurStyle: .dark)
            
            alertController.addAction(UIAlertAction(title: "Play".localized, style: .default) { _ in
                AppDelegate.shared.play(Movie(download.mediaMetadata) ?? Episode(download.mediaMetadata)!, torrent: Torrent()) // No torrent metadata necessary, media is loaded from disk.
            })
            alertController.addAction(UIAlertAction(title: "Delete Download".localized, style: .destructive) { _ in
                PTTorrentDownloadManager.shared().delete(download)
                button.downloadState = .normal
                didDeleteHandler?()
            })
            alertController.addAction(UIAlertAction(title: "Cancel".localized, style: .cancel, handler: nil))
            
            alertController.popoverPresentationController?.sourceView = button
            alertController.show(animated: true)
        case .downloading:
            download.pause()
            button.downloadState = .paused
        case .paused:
            download.resume()
            button.downloadState = .downloading
        default:
            break
        }
    }
    
    func downloadButton(_ button: DownloadButton?, wantsToStop download: PTTorrentDownload, didStopHandler: (() -> Void)? = nil) {
        let alertController = UIAlertController(title: "Stop Download".localized, message: "Are you sure you want to stop the download?".localized, preferredStyle: .alert)
        
        alertController.addAction(UIAlertAction(title: "Cancel".localized, style: .cancel, handler: nil))
        
        alertController.addAction(UIAlertAction(title: "Stop".localized, style: .destructive) { _ in
            PTTorrentDownloadManager.shared().stop(download)
            button?.downloadState = .normal
            didStopHandler?()
        })
        
        alertController.show(animated: true)
    }
    
    func download(_ download: PTTorrentDownload, failedWith error: Error) {
        let alertController = UIAlertController(title: "Download Failed".localized, message: error.localizedDescription, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK".localized, style: .default, handler: nil))
        alertController.show(animated: true)
    }
    
    // MARK: - PCTPlayerViewControllerDelegate
    
    #if os(iOS)
    
    func playerViewControllerPresentCastPlayer(_ playerViewController: PCTPlayerViewController) {
        dismiss(animated: true) { [unowned self] in
            let castPlayerViewController = UIStoryboard.main.instantiateViewController(withIdentifier: "CastPlayerViewController") as! CastPlayerViewController
            castPlayerViewController.media = playerViewController.media
            castPlayerViewController.streamer = playerViewController.streamer
            castPlayerViewController.localPathToMedia = playerViewController.localPathToMedia
            castPlayerViewController.directory = playerViewController.directory
            castPlayerViewController.url = playerViewController.url
            castPlayerViewController.startPosition = TimeInterval(playerViewController.progressBar.progress)
            self.present(castPlayerViewController, animated: true)
        }
    }
    
    #endif
    
    func playNext(_ episode: Episode) {
        chooseQuality(nil, media: episode) { [unowned self] torrent in
            self.play(episode, torrent: torrent)
        }
    }
    
    private func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)? = nil) {
        guard let rootViewController = window?.rootViewController else { return }
        rootViewController.present(viewControllerToPresent, animated: flag, completion: completion)
    }
    
    private func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        guard let rootViewController = window?.rootViewController else { return }
        rootViewController.dismiss(animated: flag, completion: completion)
    }
    
    // MARK: - Presentation
    
    private var activeViewController: UIViewController? {
        return (tabBarController.selectedViewController as? UINavigationController)?.viewControllers.last
    }
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        if presented is PreloadTorrentViewController && activeViewController is DetailViewController {
            return PreloadTorrentViewControllerAnimatedTransitioning(isPresenting: true)
        }
        return nil
        
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        if dismissed is PreloadTorrentViewController && activeViewController is DetailViewController {
            return PreloadTorrentViewControllerAnimatedTransitioning(isPresenting: false)
        }
        return nil
    }
}
