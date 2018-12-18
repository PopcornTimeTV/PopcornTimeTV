

import UIKit

protocol ContinueWatchingCollectionViewCellDelegate: class {
    func cell(_ cell: ContinueWatchingCollectionViewCell, didDetectLongPressGesture: UILongPressGestureRecognizer)
}

class ContinueWatchingCollectionViewCell: BaseCollectionViewCell {
    
    @IBOutlet var subtitleLabel: UILabel!
    @IBOutlet var progressView: UIProgressView!
    
    weak var delegate: ContinueWatchingCollectionViewCellDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        let gesture = UILongPressGestureRecognizer(target: self, action: #selector(didDetectLongPress(_:)))
        addGestureRecognizer(gesture)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        [highlightView, imageView].forEach {
            $0?.layer.cornerRadius = self.bounds.width/70.0
            $0?.layer.masksToBounds = true
        }
    }
    
    @objc func didDetectLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began else { return }
        
        delegate?.cell(self, didDetectLongPressGesture: gesture)
    }
}
