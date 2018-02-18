

import UIKit
import PopcornTorrent

class PreloadTorrentViewController: UIViewController {

    @IBOutlet var progressView: UIProgressView!
    @IBOutlet var speedLabel: UILabel!
    @IBOutlet var seedsLabel: UILabel!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var processingView: UIView!
    
    @IBOutlet var backgroundImageView: UIImageView?
    
    var streamer: PTTorrentStreamer?
    
    
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
            seedsLabel.text = "\(seeds) " + "Seeds".localized.localizedLowercase
        }
    }
    
    @IBAction func cancel() {
        streamer?.cancelStreamingAndDeleteData(false)
        dismiss(animated: true)
    }
    
}
