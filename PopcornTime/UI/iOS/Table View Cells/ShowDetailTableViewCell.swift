

import UIKit
import PopcornKit

class ShowDetailTableViewCell: UITableViewCell {
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var seasonLabel: UILabel!
    @IBOutlet var watchedButton: UIButton!
    
    var episode: Episode! {
        didSet {
            watchedButton.setImage(watchedButtonImage, for: .normal)
        }
    }
    
    var watchedButtonImage: UIImage {
        return WatchedlistManager<Episode>.episode.isAdded(episode) ? UIImage(named: "WatchedOn")! : UIImage(named: "WatchedOff")!
    }
    
    @IBAction func toggleWatched() {
        WatchedlistManager<Episode>.episode.toggle(episode)
        watchedButton.setImage(watchedButtonImage, for: .normal)
    }
}
