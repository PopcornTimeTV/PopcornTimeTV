

import Foundation
import PopcornKit

class EpisodeCollectionViewCell: UICollectionViewCell {
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var subtitleLabel: UILabel!
    @IBOutlet var watchedButton: UIButton!
    @IBOutlet var highlightView: UIView!
    
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
    
    override var isHighlighted: Bool {
        didSet {
            if self.isHighlighted {
                self.highlightView.isHidden = false
                self.highlightView.alpha = 1.0
            } else {
                UIView.animate(withDuration: 0.1, delay: 0.0, options: [.curveEaseOut, .allowUserInteraction], animations: { [unowned self] in
                    self.highlightView.alpha = 0.0
                }, completion: { _ in
                    self.highlightView.isHidden = true
                })
            }
        }
    }
}
