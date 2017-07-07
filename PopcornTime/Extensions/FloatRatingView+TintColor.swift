
import Foundation
import FloatRatingView

extension FloatRatingView {
    
    override open func tintColorDidChange() {
        super.tintColorDidChange()
        
        let imageViews = recursiveSubviews.flatMap({$0 as? UIImageView})
        
        imageViews.forEach {
            $0.tintColor = self.tintColor
        }
    }
}
