

import Foundation
import PopcornKit
import AlamofireImage


class BrowseViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    @IBOutlet var collectionView: UICollectionView!
    @IBOutlet var titleImageView: UIImageView!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var subtitleLabel: UILabel!
    @IBOutlet var backgroundImageView: UIImageView!
    @IBOutlet var gradientView: GradientView!
    
    
    var media = [Media]()
    var fanartLogoImages = [String]()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView.contentInset.left = 60
        collectionView.contentInset.right = 60
        
        PopcornKit.loadMovies { (movies, error) in
            guard let movies = movies else {
                return
            }
            
            self.media = movies.filter({$0.largeBackgroundImage != nil}).filter({ !$0.largeBackgroundImage!.isAmazonUrl}).enumerated().filter({($0.0 < 10)}).map({$0.1})
            
            self.fanartLogoImages = [String](repeating: "", count: movies.count)
            
            let group = DispatchGroup()
            
            for (index, movie) in self.media.enumerated() {
                group.enter()
                TMDBManager.shared.getLogo(forMediaOfType: .movies, id: movie.id) { (image, error) in
                    if let image = image { self.fanartLogoImages[index] = image }
                    group.leave()
                }
            }
            
            group.notify(queue: .main) {
                self.collectionView.reloadData()
            }
        }
    }
    
    // MARK: Collection view delegate
    
    
    func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) {
        collectionView.collectionViewLayout.invalidateLayout()
    }
    
    func collectionView(_ collectionView: UICollectionView, didUnhighlightItemAt indexPath: IndexPath) {
        collectionView.collectionViewLayout.invalidateLayout()
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.collectionViewLayout.invalidateLayout()
        
        let movie = media[indexPath.row]
        
        ActionHandler.shared.showMovie(movie.title, movie.id)
    }
    
    func collectionView(_ collectionView: UICollectionView, didUpdateFocusIn context: UICollectionViewFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        
        if let indexPath = context.nextFocusedIndexPath,
            let media = media[safe: indexPath.row],
            let genres = (media as? Movie)?.genres ?? (media as? Show)?.genres {
            
            self.titleLabel.alpha = 1.0
            self.titleImageView.image = nil
            
            
            if let image = media.largeBackgroundImage, let url = URL(string: image) {
                backgroundImageView.af_setImage(withURL: url, placeholderImage: UIImage(named: "Movie Placeholder"), imageTransition: .crossDissolve(animationLength), runImageTransitionIfCached: true)
            }
            
            
            if let image = fanartLogoImages[safe: indexPath.row], let url = URL(string: image) {
                titleImageView.af_setImage(withURL: url, imageTransition: .crossDissolve(animationLength)) { response in
                    guard response.result.isSuccess else { return }
                    self.titleLabel.alpha = 0.0
                }
            }
            
            var subtitle = ""
            
            if let first = genres.first {
                subtitle += first
            }
            if let second = genres[safe: 1] {
                subtitle += " & \(second)"
            }
            
            subtitleLabel.text = subtitle.uppercased()
            titleLabel.text = media.title
        }
        
        coordinator.addCoordinatedAnimations({
            collectionView.collectionViewLayout.invalidateLayout()
        }, completion: nil)
    }
    
    // MARK: Collection view data source
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath)
        
        if let imageView = cell.viewWithTag(1) as? UIImageView,
            let image = media[indexPath.row].smallCoverImage, let url = URL(string: image) {
            imageView.af_setImage(withURL: url, placeholderImage: UIImage(named: "Movie Placeholder"))
        }
        
        return cell
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return media.count
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if let cell = collectionView.cellForItem(at: indexPath), cell.isFocused && !cell.isHighlighted {
            return CGSize(width:206, height: 306)
        }
        return CGSize(width: 158, height: 233)
    }
}
