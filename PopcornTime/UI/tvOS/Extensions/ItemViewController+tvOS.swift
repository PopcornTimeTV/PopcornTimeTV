

import Foundation
import AVKit
import XCDYouTubeKit
import struct PopcornKit.Show
import struct PopcornKit.Movie

extension ItemViewController: UIViewControllerTransitioningDelegate {
    
    var visibleButtons: [TVButton] {
        return [trailerButton, playButton, seasonsButton, watchlistButton, watchedButton].flatMap({$0}).filter({$0.superview != nil})
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        setNeedsFocusUpdate()
        updateFocusIfNeeded()
        
        environmentsToFocus.removeAll()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        watchedButton?.imageView.image = watchedButtonImage
        watchlistButton?.imageView.image = watchlistButtonImage
        
        summaryTextView.buttonWasPressed = moreButtonWasPressed
        summaryTextView.text = media.summary
        
        environmentsToFocus = visibleButtons
        
        
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
            
            if let genre = movie.genres.first?.localizedCapitalized {
                appendSection("Genre".localized.localizedUppercase, [genre])
            }
            
            let directors = movie.crew.filter({$0.roleType == .director}).flatMap({$0.name})
            
            if !directors.isEmpty {
                let isSingular = directors.count == 1
                appendSection(isSingular ? "Director".localized.localizedUppercase : "Directors".localized.localizedUppercase, directors)
            }
            
            let actors = movie.actors.flatMap({$0.name})
            
            if !actors.isEmpty {
                appendSection("Staring".localized.localizedUppercase, actors)
            }
            
            peopleTextView?.attributedText = peopleText
            
            let subtitle = NSMutableAttributedString(string: "\(movie.formattedRuntime)\t\(movie.year)")
            attributedString(between: movie.certification, "HD", "CC").forEach({subtitle.append($0)})
            
            subtitleLabel.attributedText = subtitle
            ratingView.rating = movie.rating/20.0
            
            if movie.trailerCode == nil {
                trailerButton.removeFromSuperview()
            }
            
            seasonsButton?.removeFromSuperview()
        } else if let show = media as? Show {
            titleLabel.text = ""
            infoLabel.text = "Watch".localized + " \(show.title) " + "On".localized.localizedLowercase + " \(show.network ?? "TV")"
            
            let subtitle = NSMutableAttributedString(string: "\(show.genres.first?.localizedCapitalized ?? "")\t\(show.year)")
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
    
    @IBAction func toggleWatchlist(_ sender: TVButton) {
        media.isAddedToWatchlist = !media.isAddedToWatchlist
        
        sender.imageView.image = watchlistButtonImage
    }
    
    @IBAction func toggleWatched(_ sender: TVButton) {
        media.isWatched = !media.isWatched
        
        sender.imageView.image = watchedButtonImage
    }
    
    @IBAction func showSeasons() {
        if let vc = UIStoryboard.main.instantiateViewController(withIdentifier: "SeasonPickerViewController") as? SeasonPickerViewController, let parent = parent as? ShowDetailViewController {
            vc.show = parent.show
            vc.currentSeason = parent.currentSeason
            vc.delegate = parent
            vc.transitioningDelegate = parent
            vc.modalPresentationStyle = .custom
            parent.present(vc, animated: true)
        }
    }
    
    @IBAction func playTrailer() {
        guard let id = (media as? Movie)?.trailerCode else { return }
        
        let playerController = AVPlayerViewController()
        
        playerController.transitioningDelegate = self
        
        present(playerController, animated: true)
        
        XCDYouTubeClient.default().getVideoWithIdentifier(id) { (video, error) in
            guard
                let streamUrls = video?.streamURLs,
                let qualities = Array(streamUrls.keys) as? [UInt]
                else {
                    return
            }
            
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
                
                let vc = UIAlertController(title: "Error".localized, message: "Error fetching valid trailer URL from YouTube.".localized, preferredStyle: .alert)
                
                vc.addAction(UIAlertAction(title: "OK".localized, style: .cancel, handler: nil))
                
                self.present(vc, animated: true)
                
                return
            }
            
            let player = AVPlayer(url: url)
            
            let title = AVMetadataItem(key: AVMetadataCommonKeyTitle as NSString, value: self.media.title as NSString)
            let summary = AVMetadataItem(key: AVMetadataCommonKeyDescription as NSString, value: self.media.summary as NSString)
            
            player.currentItem?.externalMetadata = [title, summary]
            
            if let string = self.media.mediumCoverImage,
                let url = URL(string: string),
                let data = try? Data(contentsOf: url) {
                let image = AVMetadataItem(key: AVMetadataCommonKeyArtwork as NSString, value: data as NSData)
                player.currentItem?.externalMetadata.append(image)
            }
            
            playerController.player = player
            player.play()
            
            
            NotificationCenter.default.addObserver(self, selector: #selector(self.playerDidFinishPlaying), name: .AVPlayerItemDidPlayToEndTime, object: nil)
        }
    }
    
    func playerDidFinishPlaying() {
        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: nil)
        dismiss(animated: true)
    }
    
    func moreButtonWasPressed(text: String?) {
        let viewController = UIStoryboard.main.instantiateViewController(withIdentifier: "TVDescriptionViewController") as! TVDescriptionViewController
        viewController.loadView()
        viewController.titleLabel.text = media.title
        viewController.textView.text = text
        viewController.transitioningDelegate = self
        viewController.modalPresentationStyle = .custom
        present(viewController, animated: true)
    }
    
    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        if let next = context.nextFocusedView {
            environmentsToFocus = [next]
            
            if next is TVButton, let parent = parent as? DetailViewController // Make sure that the scroll view is at the top when buttons are focused. This doesn't happen when expandable text view is focusable.
            {
                UIView.animate(withDuration: 2.2, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 4, options: [.curveEaseOut], animations: {
                    parent.scrollView.scrollRectToVisible(CGRect(origin: .zero, size: CGSize(width: 1, height: 1)), animated: false)
                })
            }
        }
    }
    
    // MARK: - Presentation
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        if presented is AVPlayerViewController {
            return TVFadeToBlackAnimatedTransitioning(isPresenting: true)
        } else if presented is TVDescriptionViewController {
            return TVBlurOverCurrentContextAnimatedTransitioning(isPresenting: true)
        }
        return nil
        
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        if dismissed is AVPlayerViewController {
            return TVFadeToBlackAnimatedTransitioning(isPresenting: false)
        } else if dismissed is TVDescriptionViewController {
            return TVBlurOverCurrentContextAnimatedTransitioning(isPresenting: false)
        }
        return nil
    }
}
