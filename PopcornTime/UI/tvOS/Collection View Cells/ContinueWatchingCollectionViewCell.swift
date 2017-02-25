

import Foundation

protocol ContinueWatchingCollectionViewCellDelegate: class {
    func cell(_ cell: ContinueWatchingCollectionViewCell, didDetectLongPressGesture: UILongPressGestureRecognizer)
}

class ContinueWatchingCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var subtitleLabel: UILabel!
    @IBOutlet var progressView: UIProgressView!
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var dimmingView: GradientView!
    
    weak var delegate: ContinueWatchingCollectionViewCellDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        let gesture = UILongPressGestureRecognizer(target: self, action: #selector(didDetectLongPress(_:)))
        addGestureRecognizer(gesture)
        
        focusedConstraints.append(dimmingView.leadingAnchor.constraint(equalTo: imageView.focusedFrameGuide.leadingAnchor))
        focusedConstraints.append(dimmingView.trailingAnchor.constraint(equalTo: imageView.focusedFrameGuide.trailingAnchor))
        focusedConstraints.append(dimmingView.bottomAnchor.constraint(equalTo: imageView.focusedFrameGuide.bottomAnchor))
    }
    
    func didDetectLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .ended else { return }
        
        delegate?.cell(self, didDetectLongPressGesture: gesture)
    }
}
