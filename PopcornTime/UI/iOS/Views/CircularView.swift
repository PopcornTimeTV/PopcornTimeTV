

import Foundation

@IBDesignable class CircularView: UIView {
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        layer.cornerRadius = bounds.width/2.0
        layer.masksToBounds = true
    }
}
