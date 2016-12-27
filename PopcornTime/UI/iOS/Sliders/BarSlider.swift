

import Foundation
import OBSlider

class BarSlider: OBSlider {
    
    override func trackRect(forBounds bounds: CGRect) -> CGRect {
        var customBounds = super.trackRect(forBounds: bounds)
        customBounds.size.height = 3
        customBounds.origin.y -= 1
        return customBounds
    }
    
    override func awakeFromNib() {
        self.setThumbImage(UIImage(named: "Scrubber Image"), for: .normal)
        super.awakeFromNib()
    }
}
