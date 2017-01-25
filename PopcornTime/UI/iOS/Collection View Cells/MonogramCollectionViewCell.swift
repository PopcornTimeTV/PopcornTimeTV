

import Foundation

class MonogramCollectionViewCell: UICollectionViewCell {
    @IBOutlet var headshotImageView: UIImageView!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var subtitleLabel: UILabel!
    @IBOutlet var initialsLabel: UILabel!
    @IBOutlet var noImageVisualEffectView: UIVisualEffectView!
    @IBOutlet var circularView: CircularView!
    @IBOutlet var highlightView: UIView!
    
    
    override func layoutSubviews() {
        super.layoutSubviews()
        circularView.cornerRadius = bounds.width/2.0
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
