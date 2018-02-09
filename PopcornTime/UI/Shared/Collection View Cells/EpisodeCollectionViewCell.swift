

import Foundation
import struct PopcornKit.Episode
import class PopcornKit.WatchedlistManager

class EpisodeCollectionViewCell: BaseCollectionViewCell {
    
    // iOS exclusive
    @IBOutlet var watchedButton: UIButton?
    @IBOutlet var subtitleLabel: UILabel?
    @IBOutlet var accessoryView: UIView?
    
    // tvOS exclusive
    @IBOutlet var watchedOverlay: UIView?
    
    var id: String! {
        didSet {
            updateWatchedStatus()
        }
    }
    
    #if os(tvOS)
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        
        focusedConstraints.append(watchedOverlay!.widthAnchor.constraint(equalTo: imageView.focusedFrameGuide.widthAnchor))
        focusedConstraints.append(watchedOverlay!.heightAnchor.constraint(equalTo: imageView.focusedFrameGuide.heightAnchor))
        
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(didDetectLongPress(_:)))
        addGestureRecognizer(gestureRecognizer)
    }
    
    #elseif os(iOS)
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let view = super.hitTest(point, with: event)
        return view == accessoryView ? watchedButton : view
    }
    
    #endif
    
    @objc func didDetectLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began else { return }
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
        
        UIView.animate(withDuration: .default) { 
            self.watchedOverlay?.alpha = WatchedlistManager<Episode>.episode.isAdded(self.id) ? 1.0 : 0.0
        }
        
    }
}
