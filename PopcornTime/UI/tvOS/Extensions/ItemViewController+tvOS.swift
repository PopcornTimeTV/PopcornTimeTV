

import Foundation
import struct PopcornKit.Show
import struct PopcornKit.Movie

extension ItemViewController: UIViewControllerTransitioningDelegate {
    
    var visibleButtons: [TVButton] {
        return [trailerButton, playButton, seasonsButton ?? TVButton(), watchlistButton ?? TVButton(), watchedButton ?? TVButton()].flatMap({$0}).filter({($0 as! TVButton).superview != nil}) as! [TVButton]
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
                appendSection("Starring".localized.localizedUppercase, actors)
            }
            
            peopleTextView?.attributedText = peopleText
            
            let formatter = DateComponentsFormatter()
            formatter.unitsStyle = .short
            formatter.allowedUnits = [.hour, .minute]
            
            let subtitle = NSMutableAttributedString(string: "\(formatter.string(from: TimeInterval(movie.runtime) * 60) ?? "0 min")\t\(movie.year)")
            attributedString(between: movie.certification, "HD", "CC").forEach({subtitle.append($0)})
            
            subtitleLabel.attributedText = subtitle
            ratingView.rating = movie.rating/20.0
            
            if movie.trailerCode == nil {
                trailerButton.removeFromSuperview()
            }
            
            seasonsButton?.removeFromSuperview()
        } else if let show = media as? Show {
            titleLabel.text = ""
            
            infoLabel.text = .localizedStringWithFormat("Watch %@ on %@".localized, show.title, show.network ?? "TV")
            
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
            vc.transitioningDelegate = parent as? UIViewControllerTransitioningDelegate
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
 
        #if os(iOS)
            if presented is AVPlayerViewController {
                return TVFadeToBlackAnimatedTransitioning(isPresenting: false)
            }
        #endif
        
        #if os(tvOS)
            if presented is TVDescriptionViewController {
                return TVBlurOverCurrentContextAnimatedTransitioning(isPresenting: false)
            }
        #endif
        return nil
        
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        
        #if os(iOS)
        if dismissed is AVPlayerViewController {
            return TVFadeToBlackAnimatedTransitioning(isPresenting: false)
        }
        #endif
        
        #if os(tvOS)
        if dismissed is TVDescriptionViewController {
            return TVBlurOverCurrentContextAnimatedTransitioning(isPresenting: false)
        }
        #endif

        return nil
    }
}
