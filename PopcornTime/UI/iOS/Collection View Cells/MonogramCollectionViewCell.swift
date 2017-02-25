

import Foundation

@IBDesignable class MonogramCollectionViewCell: BaseCollectionViewCell {
    
    @IBOutlet var subtitleLabel: UILabel!
    @IBOutlet var initialsLabel: UILabel!
    @IBOutlet var noImageVisualEffectView: UIVisualEffectView!
    @IBOutlet var circularView: CircularView!
    
    #if os(tvOS)
    
    @IBInspectable var subtitleLabelUnfocusedColor = UIColor(white: 1.0, alpha: 0.3)
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        subtitleLabel.textColor = subtitleLabelUnfocusedColor
        subtitleLabel.layer.zPosition = 10
        subtitleLabel.layer.shadowColor = UIColor.black.cgColor
        subtitleLabel.layer.shadowOffset = CGSize(width: 0, height: 1)
        subtitleLabel.layer.shadowRadius = 2
        subtitleLabel.layer.shadowOpacity = 0.6
        
        focusedConstraints.append(circularView.leadingAnchor.constraint(equalTo: imageView.focusedFrameGuide.leadingAnchor))
        focusedConstraints.append(circularView.trailingAnchor.constraint(equalTo: imageView.focusedFrameGuide.trailingAnchor))
    }
    
    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        super.didUpdateFocus(in: context, with: coordinator)
        
        subtitleLabel.textColor = isFocused ? titleLabelFocusedColor : subtitleLabelUnfocusedColor
    }
    
    #endif
}
