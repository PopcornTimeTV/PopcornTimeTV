

import UIKit

class CoverCollectionViewCell: BaseCollectionViewCell {
    
    @IBOutlet var watchedIndicator: UIImageView?
    
    var watched = false {
        didSet {
            watchedIndicator?.isHidden = !watched
        }
    }
    
    #if os(iOS)
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        
        [highlightView, imageView].forEach {
            $0?.layer.cornerRadius = self.bounds.width * 0.02
            $0?.layer.masksToBounds = true
        }
    }
    
    #elseif os(tvOS)
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        if let watchedIndicator = watchedIndicator {
            focusedConstraints.append(watchedIndicator.trailingAnchor.constraint(equalTo: imageView.focusedFrameGuide.trailingAnchor))
            focusedConstraints.append(watchedIndicator.topAnchor.constraint(equalTo: imageView.focusedFrameGuide.topAnchor))
        }
    }
    
    #endif
}
