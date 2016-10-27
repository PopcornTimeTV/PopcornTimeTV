

import UIKit
import PopcornKit
import AlamofireImage

class InfoViewController: UIViewController {
    
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var infoLabel: UILabel!
    @IBOutlet var descriptionLabel: UILabel!
    
    
    var media: Media! {
        didSet {
            titleLabel.text = media.title
            descriptionLabel.text = media.summary
            if let string = (media as? Movie)?.mediumCoverImage ?? (media as? Episode)?.show.mediumCoverImage, let url = URL(string: string) {
                imageView.af_setImage(withURL: url)
            }
            if let runtime = (media as? Movie)?.runtime ?? (media as? Episode)?.show.runtime, let genre = (media as? Movie)?.genres.first ?? (media as? Episode)?.show.genres.first, let year = (media as? Movie)?.year ?? (media as? Episode)?.show.year {
                infoLabel.text = runtime + " min • " + genre.capitalized + " • " + year
            }
        }
    }

}
