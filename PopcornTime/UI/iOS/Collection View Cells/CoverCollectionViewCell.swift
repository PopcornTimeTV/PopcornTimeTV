

import UIKit

class CoverCollectionViewCell: BaseCollectionViewCell {
    
    @IBOutlet var coverImageView: UIImageView!
    @IBOutlet var watchedIndicator: UIImageView!
    @IBOutlet var titleLabel: UILabel!
    
    var watched = false {
        didSet {
            watchedIndicator?.isHidden = !watched
        }
    }
    
    var hidesTitleLabelWhenUnfocused: Bool = true {
        didSet {
            titleLabel?.alpha = hidesTitleLabelWhenUnfocused ? 0 : 1
        }
    }
    
    #if os(iOS)
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        
        [highlightView, coverImageView].forEach {
            $0?.layer.cornerRadius = self.bounds.width * 0.02
            $0?.layer.masksToBounds = true
        }
    }
    
    #elseif os(tvOS)
    
    @IBOutlet var imageLabelSpacingConstraint: NSLayoutConstraint!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        titleLabel.alpha = 0
        titleLabel.layer.zPosition = 10
        titleLabel.layer.shadowColor = UIColor.black.cgColor
        titleLabel.layer.shadowOffset = CGSize(width: 0, height: 1)
        titleLabel.layer.shadowRadius = 2
        titleLabel.layer.shadowOpacity = 0.6
    }
    
    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        if hidesTitleLabelWhenUnfocused {
            coordinator.addCoordinatedAnimations({
                self.titleLabel.alpha = self.isFocused ? 1 : 0
            })
        } else {
            imageLabelSpacingConstraint.constant = isFocused ? 43 : 5
            coordinator.addCoordinatedAnimations({
                self.layoutIfNeeded()
            })
        }
    }
    
    #endif
}
