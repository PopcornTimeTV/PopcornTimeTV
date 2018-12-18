

import UIKit

class TVFadedTextView: UITextView {
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let maskLayer = CALayer()
        maskLayer.frame = bounds
        
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = CGRect(x: bounds.origin.x, y:0, width: bounds.width, height: bounds.height)
        gradientLayer.colors = [UIColor.clear.cgColor,
                                UIColor.white.cgColor,
                                UIColor.white.cgColor,
                                UIColor.clear.cgColor]
        gradientLayer.locations = [0.0, 0.05, 0.90, 1.0]
        
        maskLayer.addSublayer(gradientLayer)
        self.layer.mask = maskLayer
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        isSelectable = true
        isUserInteractionEnabled = true
        panGestureRecognizer.allowedTouchTypes = [NSNumber(integerLiteral: UITouch.TouchType.indirect.rawValue)]
    }
}
