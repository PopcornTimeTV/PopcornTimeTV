

import UIKit
import PopcornKit

class ShowDetailTableViewCell: UITableViewCell {
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var seasonLabel: UILabel!
    @IBOutlet var watchedButton: UIButton!
    
    var id: String! {
        didSet {
            watchedButton.setImage(watchedButtonImage, for: .normal)
        }
    }
    
    var watchedButtonImage: UIImage {
        return WatchedlistManager<Episode>.episode.isAdded(id) ? UIImage(named: "Watched On")! : UIImage(named: "Watched Off")!
    }
    
    @IBAction func toggleWatched() {
        WatchedlistManager<Episode>.episode.toggle(id)
        watchedButton.setImage(watchedButtonImage, for: .normal)
    }
}
