
import Foundation
import GCDWebServer
import PopcornKit

class LoadExternalTorrentViewController:UIViewController,GCDWebServerDelegate,PCTPlayerViewControllerDelegate,UIViewControllerTransitioningDelegate{
    
    @IBOutlet var infoLabel:UITextView!
    var webserver:GCDWebServer!
    
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.tabBarController?.tabBar.isHidden = true
        if webserver == nil {
            webserver=GCDWebServer()
            webserver?.addGETHandler(forBasePath: "/", directoryPath: Bundle.main.path(forResource: "torrent_upload", ofType: ""), indexFilename: "index.html", cacheAge: 3600, allowRangeRequests: false) // serve the website located in Supporting Files/torrent_upload when we receive a GET request for /
            webserver?.addHandler(forMethod: "GET", path: "/torrent", request: GCDWebServerRequest.self, processBlock: {request in
                let magnetLink = (request?.query["link"] as! String).removingPercentEncoding ?? ""// get magnet link that is inserted as a link tag from the website
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
                return GCDWebServerDataResponse(statusCode:200)
            })//handle the request that returns the magnet link
        }
        super.viewWillAppear(true)
        webserver?.start(withPort: 54320, bonjourName: "PopcornLoad")
        
        infoLabel.text = "Please navigate to the webpage \(webserver?.serverURL.absoluteString ?? "") and insert the magnet link of the torrent you would like to play"
        
    }
    
    @IBAction func exitView(_ sender: Any) {
        self.navigationController?.pop(animated: true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        if webserver != nil {
            webserver.stop()
            webserver = nil
        }
    }
    
    // MARK: - Presentation
    
    dynamic func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        if presented is PreloadTorrentViewController {
            return PreloadTorrentViewControllerAnimatedTransitioning(isPresenting: true)
        }
        return nil
        
    }
    
    dynamic func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        if dismissed is PreloadTorrentViewController {
            return PreloadTorrentViewControllerAnimatedTransitioning(isPresenting: false)
        }
        return nil
    }
    
}

