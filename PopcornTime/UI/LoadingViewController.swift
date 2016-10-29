

import UIKit
import PopcornTorrent
import AlamofireImage
import TVMLKitchen

class LoadingViewController: UIViewController {

    @IBOutlet private var progressLabel: UILabel!
    @IBOutlet private var progressView: UIProgressView!
    @IBOutlet private var speedLabel: UILabel!
    @IBOutlet private var seedsLabel: UILabel!
    @IBOutlet private var backgroundImageView: UIImageView!
    @IBOutlet private var mediaTitleLabel: UILabel!
    @IBOutlet private var streamingStatusLabel: UILabel!
    
    
    var progress: Float = 0.0 {
        didSet {
            progressView.isHidden = false
            progressLabel.isHidden = false
            progressView.progress = progress
            streamingStatusLabel.text = "Downloading..."
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
    var mediaTitle: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        UIApplication.shared.isIdleTimerDisabled = true
        if let image = backgroundImageString, let url = URL(string: image) {
            backgroundImageView.af_setImage(withURL: url)
        }
        mediaTitleLabel.text = mediaTitle
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidLoad()
        UIApplication.shared.isIdleTimerDisabled = false
    }
    
    @IBAction func cancel() {
        PTTorrentStreamer.shared().cancelStreamingAndDeleteData(UserDefaults.standard.bool(forKey: "removeCacheOnPlayerExit"))
        OperationQueue.main.addOperation {
            Kitchen.appController.navigationController.popViewController(animated: true)
        }
    }
    
}
