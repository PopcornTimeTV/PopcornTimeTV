

import UIKit

protocol ContinueWatchingCollectionViewCellDelegate: class {
    func cell(_ cell: ContinueWatchingCollectionViewCell, didDetectLongPressGesture: UILongPressGestureRecognizer)
}

class ContinueWatchingCollectionViewCell: BaseCollectionViewCell, UIGestureRecognizerDelegate {
    
    @IBOutlet var subtitleLabel: UILabel!
    @IBOutlet var progressView: UIProgressView!
    
    weak var delegate: ContinueWatchingCollectionViewCellDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        let gesture = UILongPressGestureRecognizer(target: self, action: #selector(didDetectLongPress(_:)))
        addGestureRecognizer(gesture)
        gesture.delegate = self
    }
    
    #if os(iOS)
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        [highlightView, imageView].forEach {
            $0?.layer.cornerRadius = self.bounds.width/70.0
            $0?.layer.masksToBounds = true
        }
    }
    
    #endif
    
    func didDetectLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .ended else { return }
        
        delegate?.cell(self, didDetectLongPressGesture: gesture)
    }
    
}
