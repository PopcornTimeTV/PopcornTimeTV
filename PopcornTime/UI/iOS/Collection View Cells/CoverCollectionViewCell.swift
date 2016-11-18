

import UIKit

class CoverCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var coverImage: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var yearLabel: UILabel!
    @IBOutlet weak var watchedIndicator: UIView?
    
    var watched = false {
        didSet {
            guard let watchedIndicator = watchedIndicator else { return }
            UIView.animate(withDuration: 0.25, animations: {
                watchedIndicator.isHidden = !self.watched
                watchedIndicator.alpha = self.watched ? 0.5 : 0.0
            })
        }
    }
}
