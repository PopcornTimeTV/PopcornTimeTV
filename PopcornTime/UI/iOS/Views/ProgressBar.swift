

import Foundation
import UIKit

class ProgressBar: UIVisualEffectView {
    
    @IBOutlet var remainingTimeLabel: UILabel!
    @IBOutlet var elapsedTimeLabel: UILabel!
    @IBOutlet var progressSlider: BarSlider!
    
    @IBOutlet var bufferProgressView: UIProgressView! {
        didSet {
            bufferProgressView?.layer.borderWidth = 0.6
            bufferProgressView?.layer.cornerRadius = 1.0
            bufferProgressView?.clipsToBounds = true
            bufferProgressView?.layer.borderColor = UIColor.darkText.cgColor
        }
    }
    
    var isScrubbing: Bool {
        return progressSlider.isHighlighted
    }
    
    
    var progress: CGFloat {
        get {
            return CGFloat(progressSlider.value)
        } set (value) {
            progressSlider.value = Float(value)
        }
    }
    
    var bufferProgress: CGFloat {
        get {
            return CGFloat(bufferProgressView.progress)
        } set (progress) {
            bufferProgressView.progress = Float(progress)
        }
    }
}
