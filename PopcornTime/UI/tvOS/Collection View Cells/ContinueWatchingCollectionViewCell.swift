

import Foundation

protocol ContinueWatchingCollectionViewCellDelegate: class {
    func cell(_ cell: ContinueWatchingCollectionViewCell, didDetectLongPressGesture: UILongPressGestureRecognizer)
}

class ContinueWatchingCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var subtitleLabel: UILabel!
    @IBOutlet var progressView: UIProgressView!
    @IBOutlet var imageView: UIImageView!
    
    weak var delegate: ContinueWatchingCollectionViewCellDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        let gesture = UILongPressGestureRecognizer(target: self, action: #selector(didDetectLongPress(_:)))
        addGestureRecognizer(gesture)
    }
    
    func didDetectLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .ended else { return }
        
        delegate?.cell(self, didDetectLongPressGesture: gesture)
    }
}
