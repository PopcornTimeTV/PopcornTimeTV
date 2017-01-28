

import UIKit
import AlamofireImage
import PopcornKit

class EpisodeDetailViewController: UIViewController, UIScrollViewDelegate {
    
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var subtitleLabel: UILabel!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var infoLabel: UILabel!
    @IBOutlet var summaryTextView: ExpandableTextView!
    @IBOutlet var scrollView: UIScrollView!
    
    var episode: Episode!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        subtitleLabel.text = "SEASON \(episode.season) • EPISODE \(episode.episode)"
        titleLabel.text = episode.title
        summaryTextView.text = episode.summary
        
        let info = NSMutableAttributedString(string: "\(DateFormatter.localizedString(from: episode.firstAirDate, dateStyle: .medium, timeStyle: .none))\t\(episode.show.runtime ?? "0") min\t")
        attributedString(from: "HD", "CC").forEach({info.append($0)})
        infoLabel.attributedText = info
        
        
        if let image = episode.largeBackgroundImage,
            let url = URL(string: image) {
            imageView.af_setImage(withURL: url, placeholderImage: UIImage(named: "Episode Placeholder"), imageTransition: .crossDissolve(animationLength))
        }
        
        
    }
}
