

import UIKit

class CoverCollectionViewCell: UICollectionViewCell {
    @IBOutlet var coverImageView: UIImageView!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var watchedIndicator: UIImageView?
    @IBOutlet var highlightView: UIView!
    
    var watched = false {
        didSet {
            guard let watchedIndicator = watchedIndicator else { return }
            UIView.animate(withDuration: 0.25, animations: { [unowned self] in
                watchedIndicator.isHidden = !self.watched
            })
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        coverImageView.layer.borderColor = UIColor(white: 1.0, alpha: 0.1).cgColor
        coverImageView.layer.borderWidth = 1.0
    }
    
    override var isHighlighted: Bool {
        didSet {
            highlightView.isHidden = !isHighlighted
        }
    }
}
