

import Foundation
import UIKit

class ProgressSlider: UISlider {
    
    override func trackRect(forBounds bounds: CGRect) -> CGRect {
        var customBounds = super.trackRect(forBounds: bounds)
        customBounds.size.height = 3
        customBounds.origin.y -= 1
        return customBounds
    }
    
    override func awakeFromNib() {
        setThumbImage(UIImage(named: "Progress Indicator")?.colored(minimumTrackTintColor), for: .normal)
        setMinimumTrackImage(.from(color: minimumTrackTintColor), for: .normal)
        setMaximumTrackImage(.from(color: maximumTrackTintColor), for: .normal)
        super.awakeFromNib()
    }
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        var bounds = self.bounds
        bounds = bounds.insetBy(dx: 0, dy: -5)
        return bounds.contains(point)
    }
    
    override func thumbRect(forBounds bounds: CGRect, trackRect rect: CGRect, value: Float) -> CGRect {
        var rect = rect
        rect.size.width -= 4
        var frame = super.thumbRect(forBounds: bounds, trackRect: rect, value: value)
        frame.origin.y += rect.origin.y
        frame.origin.x += 2
        return frame
    }
    
}
