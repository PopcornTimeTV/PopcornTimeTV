

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
    
    override func awakeFromNib() {
        super.awakeFromNib()
        coverImageView.layer.borderColor = UIColor(white: 1.0, alpha: 0.1).cgColor
        coverImageView.layer.borderWidth = 1.0
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
