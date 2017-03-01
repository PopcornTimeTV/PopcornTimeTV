

import Foundation
import MarqueeLabel


@IBDesignable class BaseCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var imageView: UIImageView!
    
    @IBOutlet var highlightView: UIView?
    
    override var isHighlighted: Bool {
        didSet {
            if isHighlighted {
                highlightView?.isHidden = false
                highlightView?.alpha = 1.0
            } else {
                UIView.animate(withDuration: 0.1, delay: 0.0, options: [.curveEaseOut, .allowUserInteraction], animations: { [unowned self] in
                    self.highlightView?.alpha = 0.0
                    }, completion: { _ in
                        self.highlightView?.isHidden = true
                })
            }
        }
    }
    
    #if os(tvOS)
    
    var hidesTitleLabelWhenUnfocused: Bool = false {
        didSet {
            titleLabel.alpha = hidesTitleLabelWhenUnfocused ? 0 : 1
        }
    }
    
    @IBInspectable var titleLabelFocusedColor: UIColor = .white
    @IBInspectable var titleLabelUnfocusedColor = UIColor(white: 1.0, alpha: 0.6)
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        titleLabel.textColor = titleLabelUnfocusedColor
        titleLabel.layer.zPosition = 10
        titleLabel.layer.shadowColor = UIColor.black.cgColor
        titleLabel.layer.shadowOffset = CGSize(width: 0, height: 1)
        titleLabel.layer.shadowRadius = 2
        titleLabel.layer.shadowOpacity = 0.6
        
        focusedConstraints.append(titleLabel.widthAnchor.constraint(equalTo: imageView.focusedFrameGuide.widthAnchor))
        focusedConstraints.append(titleLabel.topAnchor.constraint(equalTo: imageView.focusedFrameGuide.bottomAnchor))
    }
    
    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        super.didUpdateFocus(in: context, with: coordinator)
        
        if hidesTitleLabelWhenUnfocused {
            coordinator.addCoordinatedAnimations({
                self.titleLabel.alpha = self.isFocused ? 1 : 0
            })
        }
        
        if let titleLabel = titleLabel as? MarqueeLabel {
            titleLabel.labelize = !isFocused
        }
        
        titleLabel.textColor = isFocused ? titleLabelFocusedColor : titleLabelUnfocusedColor
    }
    
    #endif
}
