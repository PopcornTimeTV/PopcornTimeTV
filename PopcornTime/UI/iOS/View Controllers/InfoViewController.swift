

import UIKit
import PopcornKit
import FloatRatingView
import AlamofireImage
import XCDYouTubeKit

protocol InfoViewControllerDelegate: class {
    func chooseQuality(_ sender: UIButton)
}

class InfoViewController: UIViewController {
    
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var subtitleLabel: UILabel!
    @IBOutlet var genreLabel: UILabel!
    @IBOutlet var infoLabel: UILabel!
    @IBOutlet var summaryTextView: ExpandableTextView!
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var ratingView: FloatRatingView!
    @IBOutlet var trailerButton: UIButton!
    
    @IBOutlet var compactConstraints: [NSLayoutConstraint]!
    @IBOutlet var regularConstraints: [NSLayoutConstraint]!
    
    var info: (title: String, subtitle: String, genre: String, info: NSMutableAttributedString, rating: Float, summary: String, image: String?, trailerCode: String?)!
    
    weak var delegate: InfoViewControllerDelegate?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        titleLabel.text = info.title
        infoLabel.attributedText = info.info
        subtitleLabel.text = info.subtitle
        genreLabel.text = info.genre
        
        summaryTextView.text = info.summary
        ratingView.rating = info.rating/20.0
        
        if let image = info.image, let url = URL(string: image) {
            imageView.af_setImage(withURL: url)
        }
        
        trailerButton.isHidden = info.trailerCode == nil
        
    }
    
    @IBAction func playTrailer() {
        let vc = XCDYouTubeVideoPlayerViewController(videoIdentifier: info.trailerCode!)
        present(vc, animated: true, completion: nil)
    }
    
    @IBAction func play(_ sender: UIButton) {
        delegate?.chooseQuality(sender)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        let isCompact = traitCollection.horizontalSizeClass == .compact
        
        for constraint in compactConstraints {
            constraint.priority = isCompact ? 999 : 240
        }
        for constraint in regularConstraints {
            constraint.priority = isCompact ? 240 : 999
        }
        
        titleLabel.font = isCompact ? UIFont.systemFont(ofSize: 40, weight: UIFontWeightHeavy) : UIFont.systemFont(ofSize: 50, weight: UIFontWeightHeavy)
        
        // Don't animate if when the view is being first presented. 
        if previousTraitCollection != nil {
            UIView.animate(withDuration: animationLength, animations: {
                self.view.layoutIfNeeded()
            })
        }
    }

}
