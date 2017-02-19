

import UIKit
import PopcornKit
import AlamofireImage
import CSStickyHeaderFlowLayout

class ContinueWatchingCollectionReusableView: UICollectionReusableView, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    @IBOutlet var collectionView: UICollectionView!
    
    var onDeck = [Media]()
    var workItem: DispatchWorkItem!
    var type: Trakt.MediaType!
    
    let minItemSize = CGSize(width: 420, height: 260)
    
    override func awakeFromNib() {
        super.awakeFromNib()

        collectionView.contentInset.left = 15
        collectionView.register(UINib(nibName: String(describing: ContinueWatchingCollectionViewCell.self), bundle: nil), forCellWithReuseIdentifier: "cell")
    }
    
    func refreshOnDeck() {
        workItem?.cancel()
        workItem = DispatchWorkItem { [unowned self] in
            let group = DispatchGroup()
            var media = [Media]()
            
            let completion: ([Media]) -> Void = { media in
                self.onDeck = media.sorted(by: {$0.0.title < $0.1.title})
                self.collectionView.reloadData()
                self.layoutSubviews()
            }
            
            if self.type == .movies {
                WatchedlistManager<Movie>.movie.getOnDeck().forEach { (id) in
                    group.enter()
                    PopcornKit.getMovieInfo(id) { (movie, error) in
                        if let movie = movie { media.append(movie) }
                        group.leave()
                    }
                }
            } else if self.type == .episodes {
                WatchedlistManager<Episode>.episode.getOnDeck().forEach { (id) in
                    group.enter()
                    PopcornKit.getEpisodeInfo(Int(id)!) { (episode, error) in
                        if let episode = episode { media.append(episode) }
                        group.leave()
                    }
                }
            }

            group.notify(queue: .main) {
                completion(media)
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25, execute: workItem) // Because function is being called from `collectionView:viewForSupplementaryElementOfKind:at:` it would be inefficent to actually refresh the view every time the function is called.
    }
    
    // MARK: - Collection view data source
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return onDeck.isEmpty ? 0 : 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return onDeck.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! ContinueWatchingCollectionViewCell
        
        let media = onDeck[indexPath.row]
        let placeholder = media is Movie ? "Movie Placeholder" : "Episode Placeholder"
        
        if let image = media.mediumBackgroundImage,
            let url = URL(string: image) {
            cell.imageView.af_setImage(withURL: url, placeholderImage: UIImage(named: placeholder), imageTransition: .crossDissolve(animationLength))
        } else {
            cell.imageView.image = UIImage(named: placeholder)
        }
        
        if let episode = media as? Episode {
            cell.titleLabel.text = episode.show.title
            cell.subtitleLabel.text = "Season \(episode.season), Episode \(episode.episode)"
            cell.progressView.progress = WatchedlistManager<Episode>.episode.currentProgress(episode.id)
        } else if let movie = media as? Movie {
            cell.titleLabel.text = movie.title
            cell.progressView.progress = WatchedlistManager<Movie>.movie.currentProgress(movie.id)
            if let runtime = Float(movie.runtime) {
                cell.subtitleLabel.text = "\(Int(runtime - (runtime * cell.progressView.progress))) mins Remaining"
            }
        }
        
        return cell
    }
    
    // MARK: - Collection view delegate
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    }
    
    // MARK: - Layout
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        collectionView.performBatchUpdates(nil) { [unowned self] _ in
            if let parentCollectionView = self.superview as? UICollectionView,
                let layout = parentCollectionView.collectionViewLayout as? CSStickyHeaderFlowLayout {
                
                let itemHeight = self.collectionView(self.collectionView, layout: self.collectionView.collectionViewLayout, sizeForItemAt: IndexPath(item: 0, section: 0)).height
                let section = (self.collectionView.collectionViewLayout as! UICollectionViewFlowLayout).sectionInset
                let content = self.collectionView.contentInset
                
                let size   = CGSize(width: parentCollectionView.bounds.width, height: itemHeight + section.top + section.bottom + content.top + content.bottom)
                
                layout.parallaxHeaderMinimumReferenceSize = self.onDeck.isEmpty ? .zero : size
                layout.parallaxHeaderReferenceSize        = self.onDeck.isEmpty ? .zero : size
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        guard let flowLayout = collectionViewLayout as? UICollectionViewFlowLayout else { return .zero }
        
        let content = collectionView.contentInset
        let section = flowLayout.sectionInset
        
        let itemSpacing = flowLayout.minimumLineSpacing + content.left + content.right + section.left + section.right
        
        let estimatedWidth = parentViewController!.view.bounds.width - itemSpacing
        
        if estimatedWidth > minItemSize.width {
            return minItemSize
        }
        
        let ratio = estimatedWidth/23
        let height = 19 * ratio
        
        return CGSize(width: estimatedWidth, height: height)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        (collectionView.collectionViewLayout as? UICollectionViewFlowLayout)?.minimumLineSpacing = traitCollection.horizontalSizeClass == .regular ? 30 : 10
        self.layoutSubviews()
    }
}
