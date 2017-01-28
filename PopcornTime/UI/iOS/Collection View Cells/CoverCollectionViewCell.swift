

import UIKit

class CoverCollectionViewCell: UICollectionViewCell {
    @IBOutlet var coverImageView: UIImageView!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var watchedIndicator: UIImageView?
    @IBOutlet var highlightView: UIView!
    
    var watched = false {
        didSet {
            guard let watchedIndicator = watchedIndicator else { return }
            watchedIndicator.isHidden = !watched
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        highlightView.layer.cornerRadius   = frame.width * 0.02
        coverImageView.layer.cornerRadius  = frame.width * 0.02
        coverImageView.layer.masksToBounds = true
        highlightView.layer.masksToBounds  = true
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
