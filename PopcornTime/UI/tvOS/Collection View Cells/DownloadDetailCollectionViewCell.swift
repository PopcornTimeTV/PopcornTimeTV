

import Foundation

protocol DownloadCollectionViewCellDelegate: class {
    func cell(_ cell: DownloadCollectionViewCell, longPressDetected gesture: UILongPressGestureRecognizer)
}

class DownloadCollectionViewCell: BaseCollectionViewCell {
    
    @IBOutlet var blurView: UIVisualEffectView!
    @IBOutlet var progressView: UIDownloadProgressView!
    @IBOutlet var pausedImageView: UIImageView!
    
    
    var downloadState: DownloadButton.State = .normal {
        didSet {
            guard downloadState != oldValue else { return }
            
            invalidateAppearance()
        }
    }
    
    var progress: Float = 0 {
        didSet {
            progressView.endAngle = ((2 * CGFloat.pi) * CGFloat(progress)) + progressView.startAngle
        }
    }
    
    weak var delegate: DownloadCollectionViewCellDelegate?
    
    @objc func longPressDetected(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began else { return }
        delegate?.cell(self, longPressDetected: gesture)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        let gesture = UILongPressGestureRecognizer(target: self, action: #selector(longPressDetected(_:)))
        addGestureRecognizer(gesture)
        
        focusedConstraints.append(blurView.heightAnchor.constraint(equalTo: imageView.focusedFrameGuide.heightAnchor))
        focusedConstraints.append(blurView.widthAnchor.constraint(equalTo: imageView.focusedFrameGuide.widthAnchor))
        
        progressView.endAngle = .pi * 1.5
    }
    
    func invalidateAppearance() {
        pausedImageView.isHidden = downloadState != .paused
        progressView.isFilled = downloadState != .paused
        blurView.isHidden = downloadState == .downloaded
    }
    
}
