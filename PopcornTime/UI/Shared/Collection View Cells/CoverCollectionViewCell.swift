

import UIKit
import PopcornKit

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

extension CoverCollectionViewCell: CellCustomizing {

    func configureCellWith<T>(_ item: T) {

        guard let media = item as? Media else { print(">>> initializing cell with invalid item"); return }

        let placeholder = media is Movie ? "Movie Placeholder" : "Episode Placeholder"

        self.titleLabel.text = media.title
        self.watched = media.isWatched

        #if os(tvOS)
            self.hidesTitleLabelWhenUnfocused = true
        #endif

        if let image = media.smallCoverImage,
            let url = URL(string: image) {
            self.imageView.af_setImage(withURL: url, placeholderImage: UIImage(named: placeholder), imageTransition: .crossDissolve(.default))
        } else {
            self.imageView.image = UIImage(named: placeholder)
        }
    }
}
