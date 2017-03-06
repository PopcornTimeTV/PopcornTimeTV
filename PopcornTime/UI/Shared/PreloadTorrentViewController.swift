

import UIKit
import PopcornTorrent

class PreloadTorrentViewController: UIViewController {

    @IBOutlet var progressView: UIProgressView!
    @IBOutlet var speedLabel: UILabel!
    @IBOutlet var seedsLabel: UILabel!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var processingView: UIView!
    
    @IBOutlet var backgroundImageView: UIImageView?
    
    /// If torrent hasn't begun processing, use this variable to make sure processing should still continue.
    var shouldCancelStreaming: Bool = false
    
    
    var progress: Float = 0.0 {
        didSet {
            progressView.isHidden = false
            processingView.isHidden = true
            progressView.progress = progress
        }
    }
    
    var speed: Int = 0 {
        didSet {
            speedLabel.isHidden = false
            speedLabel.text = ByteCountFormatter.string(fromByteCount: Int64(speed), countStyle: .binary) + "/s"
        }
    }
    
    var seeds: Int = 0 {
        didSet {
            seedsLabel.isHidden = false
            seedsLabel.text = "\(seeds) seeds"
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        UIApplication.shared.isIdleTimerDisabled = false
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        UIApplication.shared.isIdleTimerDisabled = true
    }
    
    @IBAction func cancel() {
        PTTorrentStreamer.shared().cancelStreamingAndDeleteData(UserDefaults.standard.bool(forKey: "removeCacheOnPlayerExit"))
        shouldCancelStreaming = true
        dismiss(animated: true, completion: nil)
    }
    
    #if os(iOS)
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    #endif
    
}
