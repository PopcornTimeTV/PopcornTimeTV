

import UIKit
import PopcornKit
import AlamofireImage

class ContinueWatchingCollectionViewController: UICollectionViewController {
    
    var onDeck = [Media]()

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return onDeck.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! ContinueWatchingCollectionViewCell
        
        let media = onDeck[indexPath.row]
        
        if let image = media.mediumBackgroundImage,
            let url = URL(string: image) {
            cell.imageView.af_setImage(withURL: url, placeholderImage: UIImage(named: "Episode Placeholder"), imageTransition: .crossDissolve(animationLength))
        } else {
            cell.imageView = nil
        }
        
        cell.titleLabel.text = media.title
        
        if let episode = media as? Episode {
            cell.subtitleLabel.text = "\(episode.show.title): S\(episode.season):E\(episode.episode)"
            cell.progressView.progress = WatchedlistManager<Episode>.episode.currentProgress(episode.id)
        } else {
           cell.progressView.progress = WatchedlistManager<Movie>.movie.currentProgress(media.id)
        }
        
        return cell
    }
}
