

import Foundation
import struct PopcornKit.Show
import struct PopcornKit.Movie
import PopcornTorrent.PTTorrentDownloadManager

typealias TVExpandableTextView = UIExpandableTextView
typealias TVButton = UIButton

extension ItemViewController {
    
    var watchlistButtonImage: UIImage? {
        return media.isAddedToWatchlist ? UIImage(named: "Watchlist On") : UIImage(named: "Watchlist Off")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        PTTorrentDownloadManager.shared().add(self)
        downloadButton?.addTarget(self, action: #selector(stopDownload(_:)), for: .applicationReserved)
        
        titleLabel.text = media.title
        summaryTextView.text = media.summary
        
        if let image = media.mediumCoverImage, let url = URL(string: image) {
            imageView?.af_setImage(withURL: url)
        }
        
        if let movie = media as? Movie {
            let formatter = DateComponentsFormatter()
            formatter.unitsStyle = .short
            formatter.allowedUnits = [.hour, .minute]
            
            subtitleLabel.text = formatter.string(from: TimeInterval(movie.runtime) * 60) ?? "0 min"
            genreLabel?.text = movie.genres.first?.localizedCapitalized ?? ""
            
            let info = NSMutableAttributedString(string: "\(movie.year)")
            attributedString(with: 10, between: movie.certification, "HD", "CC").forEach({info.append($0)})
            
            infoLabel.attributedText = info
            ratingView.rating = movie.rating/20.0
            
            movie.trailerCode == nil ? trailerButton.removeFromSuperview() : ()
        } else if let show = media as? Show {
            subtitleLabel.text = show.network ?? "TV"
            genreLabel?.text = show.genres.first?.localizedCapitalized ?? ""
            
            let info = NSMutableAttributedString(string: "\(show.year)")
            attributedString(with: 10, between: "HD", "CC").forEach({info.append($0)})
            
            infoLabel.attributedText = info
            ratingView.rating = show.rating/20.0
            
            trailerButton.isHidden = true
            downloadButton?.isHidden = true
        }
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
            UIView.animate(withDuration: .default, animations: {
                self.view.layoutIfNeeded()
            })
        }
    }
}
