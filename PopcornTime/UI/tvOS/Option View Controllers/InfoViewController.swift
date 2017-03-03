

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
                
                let info = NSMutableAttributedString(string: "\(movie.formattedRuntime)\t\(movie.year)\t")
                attributedString(between: movie.certification, "HD", "CC").forEach({info.append($0)})
                
                infoLabel.attributedText = info
            } else if let episode = media as? Episode {
                if let imageString = episode.show.smallCoverImage,
                    let imageUrl = URL(string: imageString) {
                    imageView.af_setImage(withURL: imageUrl)
                }
                
                let season = "S\(episode.season):E\(episode.episode)"
                let date = DateFormatter.localizedString(from: episode.firstAirDate, dateStyle: .medium, timeStyle: .none)
                let runtime = episode.show.formattedRuntime ?? "0 min"
                let genre = episode.show.genres.first?.capitalized ?? ""
                
                
                let info = NSMutableAttributedString(string: [season, date, runtime, genre].joined(separator: "\t"))
                attributedString(between: "HD", "CC").forEach({info.append($0)})
                
                infoLabel.attributedText = info
            }
        }
    }
}
