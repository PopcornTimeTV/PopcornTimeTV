

import Foundation
import struct PopcornKit.Show
import struct PopcornKit.Movie
import class AVKit.AVPlayerViewController
import class PopcornTorrent.PTTorrentDownloadManager

extension ItemViewController: UIViewControllerTransitioningDelegate {
    
    var visibleButtons: [TVButton] {
        return [trailerButton, playButton, seasonsButton, watchlistButton, watchedButton].flatMap({$0}).filter({$0.superview != nil})
    }
    
    var watchlistButtonImage: UIImage? {
        return media.isAddedToWatchlist ? UIImage(named: "Remove") : UIImage(named: "Add")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        setNeedsFocusUpdate()
        updateFocusIfNeeded()
        
        environmentsToFocus.removeAll()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        PTTorrentDownloadManager.shared().add(self)
        downloadButton.addTarget(self, action: #selector(stopDownload(_:)), for: .applicationReserved)
        
        summaryTextView.buttonWasPressed = moreButtonWasPressed
        summaryTextView.text = media.summary
        
        environmentsToFocus = visibleButtons
        
        reloadData()
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .seconds(1), execute: {
            self.setNeedsFocusUpdate()
            self.updateFocusIfNeeded()
        })
    }
    
    func reloadData() {
        if let movie = media as? Movie {
            titleLabel.text = ""
            infoLabel.text = ""
            
            let formatter = DateComponentsFormatter()
            formatter.unitsStyle = .short
            formatter.allowedUnits = [.hour, .minute]
            
            let runtime = formatter.string(from: TimeInterval(movie.runtime) * 60)
            let year = movie.year
            
            let subtitle = NSMutableAttributedString(string: [runtime, year].flatMap({$0}).joined(separator: "\t"))
            attributedString(colored: isDark ? .white : .black, between: movie.certification, "HD", "CC").forEach({subtitle.append($0)})
            
            subtitleLabel.attributedText = subtitle
            ratingView.rating = Double(movie.rating)/20.0
            
            let peopleText = NSMutableAttributedString()
            
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .right
            
            let appendSection: (String, [String]) -> Void = { (title, items) in
                let titleAttributes = [NSAttributedStringKey.paragraphStyle: paragraphStyle,
                                       NSAttributedStringKey.font: UIFont.systemFont(ofSize: 24, weight: UIFont.Weight.bold),
                                       NSAttributedStringKey.foregroundColor: self.isDark ? UIColor(white: 1, alpha: 0.8) : UIColor(white: 0, alpha: 0.8)]
                
                let isFirstSection = peopleText.length == 0
                peopleText.append(NSAttributedString(string: (!isFirstSection ? "\n" : "") + title + "\n", attributes: titleAttributes))
                
                let itemAttribtues = [NSAttributedStringKey.paragraphStyle: paragraphStyle,
                                      NSAttributedStringKey.font: UIFont.systemFont(ofSize: 31, weight: UIFont.Weight.medium),
                                      NSAttributedStringKey.foregroundColor: self.isDark ? UIColor(white: 1, alpha: 0.5) : UIColor(white: 0, alpha: 0.5)]
                
                items.forEach({peopleText.append(NSAttributedString(string: $0 + "\n", attributes: itemAttribtues))})
            }
            
            if let genre = movie.genres.first?.localizedCapitalized {
                appendSection("Genre".localized.localizedUppercase, [genre])
            }
            
            let directors = movie.crew.filter({$0.roleType == .director}).flatMap({$0.name+" "})
            
            if !directors.isEmpty {
                let isSingular = directors.count == 1
                appendSection(isSingular ? "Director".localized.localizedUppercase : "Directors".localized.localizedUppercase, [String(directors)])
            }
            
            let actors = movie.actors.flatMap({$0.name+" "})
            
            if !actors.isEmpty {
                appendSection("Starring".localized.localizedUppercase, [String(actors)])
            }
            
            peopleTextView?.attributedText = peopleText
            
            if movie.trailerCode == nil {
                trailerButton.removeFromSuperview()
            }
            
            seasonsButton?.removeFromSuperview()
        } else if let show = media as? Show {
            titleLabel.text = ""
            peopleTextView?.text = ""
            
            infoLabel.text = .localizedStringWithFormat("Watch %@ on %@".localized, show.title, show.network ?? "TV")
            
            let genre = show.genres.first?.localizedCapitalized
            let year = show.year
            
            let subtitle = NSMutableAttributedString(string: [genre, year].flatMap({$0}).joined(separator: "\t"))
            attributedString(colored: isDark ? .white : .black, between: "HD", "CC").forEach({subtitle.append($0)})
            
            subtitleLabel.font = UIFont.systemFont(ofSize: 31, weight: UIFont.Weight.medium)
            subtitleLabel.attributedText = subtitle
            
            ratingView.rating = Double(show.rating)/20.0
            trailerButton.removeFromSuperview()
            if show.latestUnwatchedEpisode() == nil {
                playButton.removeFromSuperview()
            }
            watchedButton?.removeFromSuperview()
            if show.seasonNumbers.count == 1 {
                seasonsButton?.removeFromSuperview()
            }
            downloadButton?.removeFromSuperview()
        }
    }
    
    @IBAction func toggleWatchlist(_ sender: TVButton) {
        media.isAddedToWatchlist = !media.isAddedToWatchlist
        sender.setImage(watchlistButtonImage, for: .normal)
    }
    
    @IBAction func toggleWatched(_ sender: TVButton) {
        media.isWatched = !media.isWatched
        sender.setImage(watchedButtonImage, for: .normal)
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
