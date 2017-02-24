

import UIKit
import PopcornKit
import FloatRatingView
import AlamofireImage

class ItemViewController: UIViewController {
    
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var subtitleLabel: UILabel!
    @IBOutlet var infoLabel: UILabel!
    
    @IBOutlet var summaryTextView: UITextView!
    @IBOutlet var ratingView: FloatRatingView!
    
    @IBOutlet var trailerButton: UIButton!
    @IBOutlet var playButton: UIButton!
    
    // iOS Exclusive
    
    @IBOutlet var imageView: UIImageView?
    @IBOutlet var genreLabel: UILabel?
    
    @IBOutlet var compactConstraints: [NSLayoutConstraint] = []
    @IBOutlet var regularConstraints: [NSLayoutConstraint] = []
    
    // tvOS Exclusive
    
    @IBOutlet var seasonsButton: UIButton?
    @IBOutlet var watchlistButton: UIButton?
    @IBOutlet var watchedButton: UIButton?
    
    @IBOutlet var peopleTextView: UITextView?
    
    
    
    var media: Media!
    
    @IBAction func play(_ sender: UIButton) {
        if let parent = parent as? DetailViewController {
            if let movie = media as? Movie {
                parent.chooseQuality(sender, media: movie)
            } else if let show = media as? Show {
                parent.chooseQuality(sender, media: show.latestUnwatchedEpisode()!)
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        parent?.prepare(for: segue, sender: sender)
    }
}
