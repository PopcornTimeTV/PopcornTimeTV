

import Foundation
import MarqueeLabel


@IBDesignable class BaseCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var highlightView: UIView?
    
    var colorPallete: ColorPallete {
        return isDark ? .light : .dark
    }
    
    override var isHighlighted: Bool {
        didSet {
            if isHighlighted {
                highlightView?.isHidden = false
                highlightView?.alpha = 1.0
            } else {
                UIView.animate(withDuration: 0.1,
                               delay: 0.0, options: [.curveEaseOut, .allowUserInteraction],
                               animations: { [unowned self] in
                                self.highlightView?.alpha = 0.0
                    }) { _ in
                        self.highlightView?.isHidden = true
                }
            }
        }
    }
    
    var isDark = true {
        didSet {
            guard isDark != oldValue else { return }
            
            titleLabel.textColor = isFocused ? .white : colorPallete.primary
            titleLabel.layer.shadowColor = isDark ? UIColor.black.cgColor : UIColor.clear.cgColor
        }
    }
    
    #if os(tvOS)
    
    var hidesTitleLabelWhenUnfocused: Bool = false {
        didSet {
            titleLabel.alpha = hidesTitleLabelWhenUnfocused ? 0 : 1
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        titleLabel.textColor = colorPallete.primary
        titleLabel.layer.zPosition = 10
        titleLabel.layer.shadowColor = UIColor.black.cgColor
        titleLabel.layer.shadowOffset = CGSize(width: 0, height: 1)
        titleLabel.layer.shadowRadius = 2
        titleLabel.layer.shadowOpacity = 0.6
        
        focusedConstraints.append(titleLabel.widthAnchor.constraint(equalTo: imageView.focusedFrameGuide.widthAnchor))
        focusedConstraints.append(titleLabel.topAnchor.constraint(equalTo: imageView.focusedFrameGuide.bottomAnchor, constant: 3))
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
        
        titleLabel.textColor = isFocused ? .white : colorPallete.primary
        titleLabel.layer.shadowColor = isDark || isFocused ? UIColor.black.cgColor : UIColor.clear.cgColor
    }
    
    #endif
}
