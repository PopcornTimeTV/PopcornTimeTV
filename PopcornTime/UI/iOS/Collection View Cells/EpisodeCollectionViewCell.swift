

import Foundation
import PopcornKit

class EpisodeCollectionViewCell: BaseCollectionViewCell {
    
    // iOS exclusive
    @IBOutlet var watchedButton: UIButton?
    @IBOutlet var subtitleLabel: UILabel?
    
    // tvOS exclusive
    @IBOutlet var watchedOverlay: UIView?
    
    var id: String! {
        didSet {
            updateWatchedStatus()
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        if UIDevice.current.userInterfaceIdiom == .tv {
            let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(didDetectLongPress(_:)))
            addGestureRecognizer(gestureRecognizer)
        }
    }
    
    func didDetectLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .ended else { return }
        toggleWatched()
    }
    
    var watchedButtonImage: UIImage? {
        return WatchedlistManager<Episode>.episode.isAdded(id) ? UIImage(named: "Watched On") : UIImage(named: "Watched Off")
    }
    
    @IBAction func toggleWatched() {
        WatchedlistManager<Episode>.episode.toggle(id)
        updateWatchedStatus()
    }
    
    func updateWatchedStatus() {
        watchedButton?.setImage(watchedButtonImage, for: .normal)
        
        UIView.animate(withDuration: animationLength) { 
            self.watchedOverlay?.alpha = WatchedlistManager<Episode>.episode.isAdded(self.id) ? 1.0 : 0.0
        }
        
    }
}
