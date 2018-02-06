
import Foundation
import PopcornKit

extension MoviesViewController:UISearchBarDelegate,PCTPlayerViewControllerDelegate,UIViewControllerTransitioningDelegate{
    
    func playerViewControllerPresentCastPlayer(_ playerViewController: PCTPlayerViewController) {
        func playerViewControllerPresentCastPlayer(_ playerViewController: PCTPlayerViewController) {
            dismiss(animated: true) // Close player view controller first.
            let castPlayerViewController = storyboard?.instantiateViewController(withIdentifier: "CastPlayerViewController") as! CastPlayerViewController
            castPlayerViewController.media = playerViewController.media
            castPlayerViewController.localPathToMedia = playerViewController.localPathToMedia
            castPlayerViewController.directory = playerViewController.directory
            castPlayerViewController.url = playerViewController.url
            castPlayerViewController.startPosition = TimeInterval(playerViewController.progressBar.progress)
            present(castPlayerViewController, animated: true)
        }
    }
    
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        var magnetLink = searchBar.text! // get magnet link that is inserted as a link tag from the website
        magnetLink = magnetLink.removingPercentEncoding!
        DispatchQueue.main.async {
            let userTorrent = Torrent.init(health: .excellent, url: magnetLink, quality: "1080p", seeds: 100, peers: 100, size: nil)
            var title = magnetLink
            if let startIndex = title.range(of: "dn="){
                title = String(title[startIndex.upperBound...])
                title = String(title[title.startIndex ... title.range(of: "&tr")!.lowerBound])
            }
            let magnetTorrentMedia = Movie.init(title: title, id: "34", tmdbId: nil, slug: "magnet-link", summary: "", torrents: [userTorrent], subtitles: [], largeBackgroundImage: nil, largeCoverImage: nil)
            
            let storyboard = UIStoryboard.main
            let loadingViewController = storyboard.instantiateViewController(withIdentifier: "PreloadTorrentViewController") as! PreloadTorrentViewController
            loadingViewController.transitioningDelegate = self
            loadingViewController.loadView()
            loadingViewController.titleLabel.text = magnetLink
            
            self.present(loadingViewController, animated: true)
            
            //Movie completion Blocks
            
            let error: (String) -> Void = { (errorMessage) in
                if self.presentedViewController != nil {
                    self.dismiss(animated: false)
                }
                let vc = UIAlertController(title: "Error".localized, message: errorMessage, preferredStyle: .alert)
                vc.addAction(UIAlertAction(title: "OK".localized, style: .cancel, handler: nil))
                self.present(vc, animated: true)
            }
            
            let finishedLoading: (PreloadTorrentViewController, UIViewController) -> Void = { (loadingVc, playerVc) in
                let flag = UIDevice.current.userInterfaceIdiom != .tv
                self.dismiss(animated: flag)
                self.present(playerVc, animated: flag)
            }
            
            //Movie player view controller calls
            
            let playViewController = storyboard.instantiateViewController(withIdentifier: "PCTPlayerViewController") as! PCTPlayerViewController
            playViewController.delegate = self
            magnetTorrentMedia.play(fromFileOrMagnetLink: magnetLink, nextEpisodeInSeries: nil, loadingViewController: loadingViewController, playViewController: playViewController, progress: 0, errorBlock: error, finishedLoadingBlock: finishedLoading)
        }// start to stream the new movie asynchronously as we do not want to mess the web server response
    }
    
    override func viewDidLoad() {
        self.magnetLinkTextField.delegate = self
        super.viewDidLoad()
    }
}

