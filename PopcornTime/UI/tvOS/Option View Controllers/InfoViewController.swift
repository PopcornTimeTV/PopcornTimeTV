

import UIKit
import PopcornKit
import AlamofireImage

class InfoViewController: UIViewController {
    
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var infoLabel: UILabel!
    @IBOutlet var descriptionLabel: UILabel!
    
    @IBOutlet var contentView: UIView!
    @IBOutlet var noInfoLabel: UILabel!
    
    
    var media: Media? {
        didSet {
            guard let media = media else {
                contentView.isHidden = true
                noInfoLabel.isHidden = false
                return
            }
            titleLabel.text = media.title
            descriptionLabel.text = media.summary
            if let movie = media as? Movie {
                if let imageString = movie.smallCoverImage,
                    let imageUrl = URL(string: imageString) {
                    imageView.af_setImage(withURL: imageUrl)
                }
                infoLabel.text = movie.runtime + " min"
                if let genre = movie.genres.first?.capitalized {
                    infoLabel.text?.append(" • " + genre)
                }
                infoLabel.text?.append(" • " + movie.year)
            } else if let episode = media as? Episode {
                if let imageString = episode.show.smallCoverImage,
                    let imageUrl = URL(string: imageString) {
                    imageView.af_setImage(withURL: imageUrl)
                }
                infoLabel.text = "Season \(episode.season) Episode \(episode.episode)"
            }
        }
    }
}
