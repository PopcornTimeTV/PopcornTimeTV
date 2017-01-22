

import UIKit
import PopcornKit
import FloatRatingView
import AlamofireImage

class InfoViewController: UIViewController {
    
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var infoLabel: UILabel!
    @IBOutlet var summaryTextView: ExpandableTextView!
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var ratingView: FloatRatingView!
    
    var info: (title: String, info: NSMutableAttributedString, rating: Float, summary: String, image: String?)!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        titleLabel.text = info.title
        infoLabel.attributedText = info.info
        
        summaryTextView.text = info.summary
        ratingView.rating = info.rating/20.0
        
        if let image = info.image, let url = URL(string: image) {
            imageView.af_setImage(withURL: url)
        }
        
    }

}
