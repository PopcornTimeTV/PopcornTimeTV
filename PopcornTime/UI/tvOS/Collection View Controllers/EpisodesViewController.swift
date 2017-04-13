

import Foundation
import struct PopcornKit.Episode
import AlamofireImage

typealias EpisodesCollectionViewController = EpisodesViewController // Keep Xcode happy

class EpisodesViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UIViewControllerTransitioningDelegate {
    
    var dataSource: [Episode] = []
    
    @IBOutlet var titleView: UIView!
    @IBOutlet var titleImageView: UIImageView!
    @IBOutlet var titleLabel: UILabel!
    
    @IBOutlet var numberOfEpisodesLabel: UILabel!
    @IBOutlet var collectionView: UICollectionView!
    
    @IBOutlet var episodeSummaryTextView: TVExpandableTextView!
    @IBOutlet var episodeTitleLabel: UILabel!
    @IBOutlet var episodeInfoTextView: UITextView!
    
    @IBOutlet var episodeTitleLabelTopConstraint: NSLayoutConstraint!
    
    let focusGuide = UIFocusGuide()
    var focusIndexPath = IndexPath(row: 0, section: 0)
    
    var itemViewController: ItemViewController? {
        get {
            if let parent = parent as? DetailViewController {
                return parent.itemViewController
            }
            return nil
        } set(vc) {
            if let parent = parent as? DetailViewController {
                parent.itemViewController = vc
            }
        }
    }
    
    var environmentsToFocus: [UIFocusEnvironment] {
        get {
            return itemViewController?.environmentsToFocus ?? []
        } set(environments) {
            itemViewController?.environmentsToFocus = environments
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        titleLabel.text = dataSource.first?.show.title
        episodeSummaryTextView.buttonWasPressed = moreButtonWasPressed
        
        view.addLayoutGuide(focusGuide)
        
        focusGuide.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        focusGuide.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        focusGuide.bottomAnchor.constraint(equalTo: episodeTitleLabel.topAnchor).isActive = true
        focusGuide.topAnchor.constraint(equalTo: collectionView.bottomAnchor).isActive = true
        
        focusGuide.preferredFocusEnvironments = [episodeSummaryTextView]
    }
    
    func moreButtonWasPressed(text: String?) {
        let viewController = UIStoryboard.main.instantiateViewController(withIdentifier: "TVDescriptionViewController") as! TVDescriptionViewController
        viewController.loadView()
        viewController.titleLabel.text = dataSource[focusIndexPath.row].title
        viewController.textView.text = text
        viewController.transitioningDelegate = self
        viewController.modalPresentationStyle = .custom
        present(viewController, animated: true)
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        collectionView.setNeedsFocusUpdate()
        collectionView.updateFocusIfNeeded()
        
        collectionView.reloadData()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if collectionView.numberOfItems(inSection: 0) == 0 {
            preferredContentSize = .zero
        } else {
            preferredContentSize = CGSize(width: view.bounds.width, height: 750 + episodeTitleLabelTopConstraint.constant)
        }
    }
    
    // MARK: - Collection view data source
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let items = dataSource.count
        let singular = items == 1
        numberOfEpisodesLabel.text = "\(items) \(singular ? "Episode".localized : "Episodes".localized)"
        return items
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! EpisodeCollectionViewCell
        
        let episode = dataSource[indexPath.row]
        
        
        cell.titleLabel.text = "\(episode.episode). \(episode.title)"
        cell.id = episode.id
        
        if let image = episode.smallBackgroundImage, let url = URL(string: image) {
            cell.imageView.af_setImage(withURL: url, placeholderImage: UIImage(named: "Episode Placeholder"), imageTransition: .crossDissolve(.default))
        } else {
            cell.imageView.image = UIImage(named: "Episode Placeholder")
        }
        
        return cell
    }
    
    // MARK: - Collection view delegate
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let parent = parent as? DetailViewController {
            parent.chooseQuality(nil, media: dataSource[indexPath.row])
        }
        
        focusIndexPath = indexPath
    }
    
    func indexPathForPreferredFocusedView(in collectionView: UICollectionView) -> IndexPath? {
        return focusIndexPath
    }
    
    
    func collectionView(_ collectionView: UICollectionView, didUpdateFocusIn context: UICollectionViewFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        
        var shouldUpdateView = false
        focusGuide.preferredFocusEnvironments = [episodeSummaryTextView]
        environmentsToFocus = [context.nextFocusedView].flatMap({$0})
        
        
        if let next = context.nextFocusedIndexPath,
            let cell = context.nextFocusedView {
            let episode = dataSource[next.row]
            
            focusIndexPath = next
            
            episodeSummaryTextView.text = episode.summary
            episodeTitleLabel.text = episode.title
            
            let airDateString = DateFormatter.localizedString(from: episode.firstAirDate, dateStyle: .medium, timeStyle: .none)
            
            let showGenre = episode.show.genres.first?.localizedCapitalized ?? ""
            episodeInfoTextView.text = "\(airDateString) \n \(showGenre)"
            
            if context.previouslyFocusedIndexPath == nil // Collection view has just gained focus, expand UI
            {
                episodeTitleLabelTopConstraint.constant = 140
                numberOfEpisodesLabel.font = .preferredFont(forTextStyle: .headline)
                shouldUpdateView = true
                
                // View should always be at the centre of the screen.
                if let parent = parent as? DetailViewController {
                    let size = parent.scrollView.bounds.size
                    let origin = parent.scrollView.convert(cell.frame.origin, from: view)
                    UIView.animate(withDuration: 2.2, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 4, options: [.curveEaseOut], animations: {
                        parent.scrollView.scrollRectToVisible(CGRect(origin: origin, size: size), animated: false)
                    })
                }
            }
        } else if let next = context.nextFocusedView, let itemViewController = itemViewController, next == itemViewController.summaryTextView || !itemViewController.visibleButtons.filter({$0 == next}).isEmpty // Collection view is loosing focus, shrink UI
        {
            episodeTitleLabelTopConstraint.constant = 15
            numberOfEpisodesLabel.font = .preferredFont(forTextStyle: .callout)
            shouldUpdateView = true
        } else if let next = context.nextFocusedView, let previous = context.previouslyFocusedIndexPath, let cell = collectionView.cellForItem(at: previous), next == episodeSummaryTextView {
            focusGuide.preferredFocusEnvironments = [cell]
        }
        
        if shouldUpdateView {
            coordinator.addCoordinatedAnimations({ [unowned self] in
                if context.previouslyFocusedIndexPath == nil {
                    self.titleView.alpha = 1.0
                } else {
                    self.titleView.alpha = 0.0
                }
                self.view.layoutIfNeeded()
            })
        }
    }
    
    // MARK: - Presentation
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        if presented is TVDescriptionViewController {
            return TVBlurOverCurrentContextAnimatedTransitioning(isPresenting: true)
        }
        return nil
        
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        if dismissed is TVDescriptionViewController {
            return TVBlurOverCurrentContextAnimatedTransitioning(isPresenting: false)
        }
        return nil
    }
}
