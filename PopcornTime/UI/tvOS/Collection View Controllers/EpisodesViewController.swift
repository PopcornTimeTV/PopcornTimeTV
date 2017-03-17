

import Foundation
import PopcornKit
import AlamofireImage

typealias EpisodesCollectionViewController = EpisodesViewController // Keep Xcode happy

class EpisodesViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    
    var dataSource: [Episode] = []
    
    @IBOutlet var titleView: UIView!
    @IBOutlet var titleImageView: UIImageView!
    @IBOutlet var titleLabel: UILabel!
    
    @IBOutlet var numberOfEpisodesLabel: UILabel!
    @IBOutlet var collectionView: UICollectionView!
    
    @IBOutlet var episodeSummaryTextView: UITextView!
    @IBOutlet var episodeTitleLabel: UILabel!
    @IBOutlet var episodeInfoTextView: UITextView!
    
    @IBOutlet var episodeTitleLabelTopConstraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        titleLabel.text = dataSource.first?.show.title
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
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
        numberOfEpisodesLabel.text = "\(items) \(singular ? "Episode" : "Episodes")"
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
    }
    
    
    func collectionView(_ collectionView: UICollectionView, didUpdateFocusIn context: UICollectionViewFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        
        var shouldUpdateView = false
        
        if let next = context.nextFocusedIndexPath,
            let cell = context.nextFocusedView {
            let episode = dataSource[next.row]
            
            episodeSummaryTextView.text = episode.summary
            episodeTitleLabel.text = episode.title
            
            let airDateString = DateFormatter.localizedString(from: episode.firstAirDate, dateStyle: .medium, timeStyle: .none)
            let showGenre = episode.show.genres.first?.capitalized ?? ""
            episodeInfoTextView.text = "\(airDateString) \n \(showGenre)"
            
            if context.previouslyFocusedIndexPath == nil // Collection view has just gained focus, expand UI
            {
                episodeTitleLabelTopConstraint.constant = 140
                numberOfEpisodesLabel.font = .systemFont(ofSize: 43, weight: UIFontWeightMedium)
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
        } else // Collection view is loosing focus, shrink UI
        {
            episodeTitleLabelTopConstraint.constant = 15
            numberOfEpisodesLabel.font = .systemFont(ofSize: 31, weight: UIFontWeightMedium)
            shouldUpdateView = true
        }
        
        guard shouldUpdateView else { return }
        
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
