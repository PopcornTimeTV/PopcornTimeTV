

import UIKit
import PopcornKit

class ShowDetailTableViewCell: UITableViewCell {
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var seasonLabel: UILabel!
    @IBOutlet var watchedButton: UIButton!
    
    var tvdbId: String! {
        didSet {
            watchedButton.setImage(watchedButtonImage, for: .normal)
        }
    }
    
    var watchedButtonImage: UIImage {
        return WatchedlistManager.episode.isAdded(tvdbId) ? UIImage(named: "WatchedOn")! : UIImage(named: "WatchedOff")!
    }
    
    @IBAction func toggleWatched() {
        WatchedlistManager.episode.toggle(tvdbId)
        watchedButton.setImage(watchedButtonImage, for: .normal)
    }
}
