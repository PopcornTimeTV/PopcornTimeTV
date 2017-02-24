

import Foundation
import XCDYoutubeKit

extension ItemViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        titleLabel.text = media.title
        summaryTextView.text = media.summary
        
        if let image = media.image, let url = URL(string: image) {
            imageView.af_setImage(withURL: url)
        }
        
        if let movie = media as? Movie {
            subtitleLabel.text = movie.formattedRuntime
            genreLabel.text = movie.genres.first?.capitalized ?? ""
            
            let info = NSMutableAttributedString(string: "\(movie.year)\t")
            attributedString(from: movie.certification, "HD", "CC").forEach({info.append($0)})
            
            infoLabel.attributedText = info
            ratingView.rating = movie.rating/20.0
            
            trailerButton.isHidden = movie.trailerCode == nil
        } else if let show = media as? Show {
            subtitleLabel.text = show.network ?? "TV"
            genreLabel.text = show.genres.first?.capitalized ?? ""
            
            let info = NSMutableAttributedString(string: "\(show.year)\t")
            attributedString(from: "HD", "CC").forEach({info.append($0)})
            
            infoLabel.attributedText = info
            ratingView.rating = show.rating/20.0
            
            trailerButton.isHidden = true
            playButton.isHidden = show.latestUnwatchedEpisode() == nil
        }
    }
    
    @IBAction func playTrailer() {
        guard let id = (media as? Movie)?.trailerCode else { return }
        let vc = XCDYouTubeVideoPlayerViewController(videoIdentifier: id)
        present(vc, animated: true, completion: nil)
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
