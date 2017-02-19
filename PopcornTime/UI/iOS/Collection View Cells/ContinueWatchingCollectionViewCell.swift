

import UIKit

class ContinueWatchingCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var subtitleLabel: UILabel!
    @IBOutlet var progressView: UIProgressView!
    @IBOutlet var highlightView: UIView!
    
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        [highlightView, imageView].forEach {
            $0?.layer.cornerRadius = self.bounds.width/70.0
            $0?.layer.masksToBounds = true
        }
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
