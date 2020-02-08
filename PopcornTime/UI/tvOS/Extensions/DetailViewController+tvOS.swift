

import Foundation
import PopcornKit

extension DetailViewController {
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if let movie = currentItem as? Movie {
            ThemeSongManager.shared.playMovieTheme(movie.title)
        } else if let show = currentItem as? Show {
            ThemeSongManager.shared.playShowTheme(Int(show.tvdbId)!)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if #available(tvOS 13, *){
            tabBarController?.tabBar.isHidden = true
        }
        navigationController?.setNavigationBarHidden(true, animated: false)
        
        watchedButton.setImage(watchedButtonImage, for: .normal)
        watchlistButton.setImage(watchlistButtonImage, for: .normal)
    }
    
    override var preferredFocusEnvironments: [UIFocusEnvironment] {
        return itemViewController.preferredFocusEnvironments
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if #available(tvOS 13, *){
            tabBarController?.tabBar.isHidden = false
        }
        navigationController?.setNavigationBarHidden(false, animated: false)
        ThemeSongManager.shared.stopTheme()
    }
    
    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        
        if let next = context.nextFocusedView as? BaseCollectionViewCell // Collection view is gaining focus, increase all header font sizes.
        {
            let font = UIFont.preferredFont(forTextStyle: .headline)
            relatedHeader.font = font
            peopleHeader.font  = font
            relatedHeader.sizeToFit()
            peopleHeader.sizeToFit()

            let frame = next.imageView.focusedFrameGuide.layoutFrame
            
            relatedBottomConstraint.constant = {
                guard next.collectionView === relatedCollectionViewController?.collectionView else {
                    return 15
                }
                
                var relativeFrame = relatedHeader.superview!.convert(frame, from: next)
                relativeFrame.origin.y = abs(frame.origin.y) + 15
                
                // If header frame intersects focused cell frame, increase spacing between.
                return relativeFrame.intersects(relatedHeader.frame) ? 37 : 15
            }()
            
            if relatedBottomConstraint.constant == 37 {
                relatedTopConstraint.constant = 21
            } else {
                relatedTopConstraint.constant = 43
            }
            
            peopleBottomConstraint.constant = {
                guard next.collectionView === peopleCollectionViewController.collectionView else {
                    return 15
                }
                
                var relativeFrame = peopleHeader.superview!.convert(frame, from: next)
                relativeFrame.origin.y = abs(frame.origin.y) + 15
                
                // If header frame intersects focused cell frame, increase spacing between.
                return relativeFrame.intersects(peopleHeader.frame) ? 43 : 15
            }()
            
            if peopleBottomConstraint.constant == 43 {
                peopleTopConstraint.constant = 15
            } else {
                peopleTopConstraint.constant = 43
            }
            
            relatedCollectionViewController != nil ? preferredContentSizeDidChange(forChildContentContainer: relatedCollectionViewController) : ()
            preferredContentSizeDidChange(forChildContentContainer: peopleCollectionViewController)
            
            coordinator.addCoordinatedAnimations({
                self.view.layoutIfNeeded()
            })
        } else if let previous = context.previouslyFocusedView as? BaseCollectionViewCell, ((relatedCollectionViewController != nil && previous.collectionView == relatedCollectionViewController.collectionView) || previous.collectionView == peopleCollectionViewController.collectionView), !(context.nextFocusedView is UICollectionViewCell), context.nextFocusedView != episodesCollectionViewController.episodeSummaryTextView, context.nextFocusedView != episodesCollectionViewController.downloadButton // Top collection view is loosing focus, decrease all header font sizes.
        {
            let font = UIFont.preferredFont(forTextStyle: .callout)
            peopleHeader.font  = font
            relatedHeader.font = font
            
            peopleBottomConstraint.constant = 8
            relatedBottomConstraint.constant = 8
            
            relatedTopConstraint.constant = 14
            peopleTopConstraint.constant = 14
            
            relatedCollectionViewController != nil ? preferredContentSizeDidChange(forChildContentContainer: relatedCollectionViewController) : ()
            preferredContentSizeDidChange(forChildContentContainer: peopleCollectionViewController)
            
            coordinator.addCoordinatedAnimations({
                let duration = UIView.inheritedAnimationDuration
                
                UIView.animate(withDuration: duration * 2, delay: 0, options: .overrideInheritedDuration, animations: {
                    self.view.layoutIfNeeded()
                })
            })
        }
    }
    
    override func shouldUpdateFocus(in context: UIFocusUpdateContext) -> Bool {
        if let nextFocusedView = context.nextFocusedView, type(of: nextFocusedView) === NSClassFromString("UITabBarButton") {
            return false
        }
        return true
    }
}
