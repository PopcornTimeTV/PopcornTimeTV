

import Foundation
import AVKit
import XCDYouTubeKit
import PopcornKit

extension ItemViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        watchlistButton?.setImage(watchlistButtonImage, for: .normal)
        watchedButton?.setImage(watchedButtonImage, for: .normal)
        
        summaryTextView.text = media.summary
        
        if let movie = media as? Movie {
            titleLabel.text = ""
            infoLabel.text = ""
            
            let peopleText = NSMutableAttributedString()
            
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .right
            
            let appendSection: (String, [String]) -> Void = { (title, items) in
                let titleAttributes = [NSParagraphStyleAttributeName: paragraphStyle, NSFontAttributeName: UIFont.systemFont(ofSize: 24, weight: UIFontWeightBold), NSForegroundColorAttributeName: UIColor(white: 1.0, alpha: 0.8)]
                
                let isFirstSection = peopleText.length == 0
                peopleText.append(NSAttributedString(string: (!isFirstSection ? "\n" : "") + title + "\n", attributes: titleAttributes))
                
                let itemAttribtues = [NSParagraphStyleAttributeName: paragraphStyle, NSFontAttributeName: UIFont.systemFont(ofSize: 31, weight: UIFontWeightMedium), NSForegroundColorAttributeName: UIColor(white: 1.0, alpha: 0.5)]
                
                items.forEach({peopleText.append(NSAttributedString(string: $0 + "\n", attributes: itemAttribtues))})
            }
            
            if let genre = movie.genres.first?.capitalized {
                appendSection("GENRE", [genre])
            }
            
            let directors = movie.crew.filter({$0.roleType == .director}).flatMap({$0.name})
            
            if !directors.isEmpty {
                let isSingular = directors.count == 1
                appendSection(isSingular ? "DIRECTOR" : "DIRECTORS", directors)
            }
            
            let actors = movie.actors.flatMap({$0.name})
            
            if !actors.isEmpty {
                appendSection("STARING", actors)
            }
            
            peopleTextView?.attributedText = peopleText
            
            let subtitle = NSMutableAttributedString(string: "\(movie.formattedRuntime)\t\(movie.year)\t")
            attributedString(between: movie.certification, "HD", "CC").forEach({subtitle.append($0)})
            
            subtitleLabel.attributedText = subtitle
            ratingView.rating = movie.rating/20.0
            
            if movie.trailerCode == nil {
                trailerButton.removeFromSuperview()
            }
            
            seasonsButton?.removeFromSuperview()
        } else if let show = media as? Show {
            titleLabel.text = ""
            infoLabel.text = "Watch \(show.title) on \(show.network ?? "TV")"
            
            let subtitle = NSMutableAttributedString(string: "\(show.genres.first?.capitalized ?? "")\t\(show.year)\t")
            attributedString(between: "HD", "CC").forEach({subtitle.append($0)})
            
            subtitleLabel.font = UIFont.systemFont(ofSize: 31, weight: UIFontWeightMedium)
            subtitleLabel.attributedText = subtitle
            peopleTextView?.text = ""
            
            ratingView.isHidden = true
            trailerButton.removeFromSuperview()
            if show.latestUnwatchedEpisode() == nil {
                playButton.removeFromSuperview()
            }
            watchedButton?.removeFromSuperview()
            if show.seasonNumbers.count == 1 {
                seasonsButton?.removeFromSuperview()
            }
        }
    }
    
    var watchlistButtonImage: UIImage? {
        return media.isAddedToWatchlist ? UIImage(named: "Remove") : UIImage(named: "Add")
    }
    
    var watchedButtonImage: UIImage? {
        return media.isWatched ? UIImage(named: "Watched On") : UIImage(named: "Watched Off")
    }
    
    @IBAction func toggleWatchlist(_ sender: UIButton) {
        media.isAddedToWatchlist = !media.isAddedToWatchlist
        
        sender.setImage(watchlistButtonImage, for: .normal)
    }
    
    @IBAction func toggleWatched(_ sender: UIButton) {
        media.isWatched = !media.isWatched
        
        sender.setImage(watchedButtonImage, for: .normal)
    }
    
    @IBAction func playTrailer() {
        guard let id = (media as? Movie)?.trailerCode else { return }
        let playerController = AVPlayerViewController()
        present(playerController, animated: true)
        XCDYouTubeClient.default().getVideoWithIdentifier(id) { (video, error) in
            guard let streamUrls = video?.streamURLs,
                let qualities = Array(streamUrls.keys) as? [UInt] else { return }
            let preferredVideoQualities = [XCDYouTubeVideoQuality.HD720.rawValue, XCDYouTubeVideoQuality.medium360.rawValue, XCDYouTubeVideoQuality.small240.rawValue]
            var videoUrl: URL?
            forLoop: for quality in preferredVideoQualities {
                if let index = qualities.index(of: quality) {
                    videoUrl = Array(streamUrls.values)[index]
                    break forLoop
                }
            }
            guard let url = videoUrl else {
                self.dismiss(animated: true)
                
                let vc = UIAlertController(title: "Oops!", message: "Error fetching valid trailer URL from Youtube.", preferredStyle: .alert)
                
                vc.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                
                self.present(vc, animated: true)
                
                return
            }
            
            playerController.player = AVPlayer(url: url)
            playerController.player!.play()
            
            NotificationCenter.default.addObserver(self, selector: #selector(self.playerDidFinishPlaying), name: .AVPlayerItemDidPlayToEndTime, object: nil)
        }
    }
    
    func playerDidFinishPlaying() {
        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: nil)
        dismiss(animated: true)
    }
}
