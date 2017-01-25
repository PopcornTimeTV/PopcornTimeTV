

import UIKit
import PopcornKit
import FloatRatingView
import AlamofireImage

class InfoViewController: UIViewController {
    
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var lengthLabel: UILabel!
    @IBOutlet var genreLabel: UILabel!
    @IBOutlet var infoLabel: UILabel!
    @IBOutlet var summaryTextView: ExpandableTextView!
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var ratingView: FloatRatingView!
    
    @IBOutlet var compactConstraints: [NSLayoutConstraint]!
    @IBOutlet var regularConstraints: [NSLayoutConstraint]!
    
    var info: (title: String, length: String, genre: String, info: NSMutableAttributedString, rating: Float, summary: String, image: String?)!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        titleLabel.text = info.title
        infoLabel.attributedText = info.info
        lengthLabel.text = info.length
        genreLabel.text = info.genre
        
        summaryTextView.text = info.summary
        ratingView.rating = info.rating/20.0
        
        if let image = info.image, let url = URL(string: image) {
            imageView.af_setImage(withURL: url)
        }
        
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        for constraint in compactConstraints {
            constraint.priority = traitCollection.horizontalSizeClass == .compact ? 999 : 240
        }
        for constraint in regularConstraints {
            constraint.priority = traitCollection.horizontalSizeClass == .compact ? 240 : 999
        }
        UIView.animate(withDuration: animationLength, animations: {
            self.view.layoutIfNeeded()
        })
    }

}
