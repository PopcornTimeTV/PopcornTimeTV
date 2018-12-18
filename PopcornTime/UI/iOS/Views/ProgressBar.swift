

import Foundation
import UIKit

class ProgressBar: UIView {
    
    @IBOutlet var remainingTimeLabel: UILabel!
    @IBOutlet var elapsedTimeLabel: UILabel!
    @IBOutlet weak var progressSlider: BarSlider!
    
    
    @IBOutlet var bufferProgressView: UIProgressView! {
        didSet {
            bufferProgressView?.layer.borderWidth = 0.6
            bufferProgressView?.layer.cornerRadius = 1.0
            bufferProgressView?.clipsToBounds = true
            bufferProgressView?.layer.borderColor = UIColor.darkText.cgColor
        }
    }
    
    var scrubbingTimeLabel: UILabel {
        get {
          return elapsedTimeLabel
        } set (label) {
            elapsedTimeLabel = label
        }
    }
    
    var isScrubbing: Bool {
        return progressSlider.isHighlighted
    }
    
    var isBuffering: Bool = false {
        didSet {
            // TODO: Show/Hide buffering UI
        }
    }
    
    var progress: Float {
        get {
            return progressSlider.value
        } set (value) {
            progressSlider.value = value
        }
    }
    
    var bufferProgress: Float {
        get {
            return bufferProgressView.progress
        } set (progress) {
            bufferProgressView.progress = progress
        }
    }
    
    var scrubbingProgress: Float {
        get {
            return progress
        } set (value) {
            progress = value
        }
    }
}
