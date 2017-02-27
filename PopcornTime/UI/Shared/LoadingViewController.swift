

import UIKit
import PopcornTorrent
import AlamofireImage

class PreloadTorrentViewController: UIViewController {

    @IBOutlet private var progressLabel: UILabel!
    @IBOutlet private var progressView: UIProgressView!
    @IBOutlet private var speedLabel: UILabel!
    @IBOutlet private var seedsLabel: UILabel!
    @IBOutlet private var backgroundImageView: UIImageView!
    
    // tvOS exclusive
    @IBOutlet private var mediaTitleLabel: UILabel?
    @IBOutlet private var streamingStatusLabel: UILabel?
    
    // iOS exclusive 
    @IBOutlet private var processingView: UIView?
    
    /// If torrent hasn't begun processing, use this variable to make sure processing should still continue.
    var shouldCancelStreaming: Bool = false
    
    
    var progress: Float = 0.0 {
        didSet {
            progressView.isHidden = false
            processingView?.isHidden = true
            progressLabel.isHidden = false
            progressView.progress = progress
            streamingStatusLabel?.text = "Downloading..."
            progressLabel.text = String(format: "%.0f%%", progress*100)
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
    
    var backgroundImageString: String?
    var mediaTitle: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let image = backgroundImageString, let url = URL(string: image) {
            backgroundImageView.af_setImage(withURL: url)
        }
        mediaTitleLabel?.text = mediaTitle
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
