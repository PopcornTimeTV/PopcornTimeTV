

import Foundation
import AlamofireImage
import PopcornKit

class EpisodesCollectionViewController: ResponsiveCollectionViewController, UICollectionViewDelegateFlowLayout {
    
    var dataSource: [Episode] = []
    
    override func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        scrollViewSnapToCell(scrollView)
    }
    
    override func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        scrollViewSnapToCell(scrollView)
    }
    
    func scrollViewSnapToCell(_ scrollView: UIScrollView) {
        guard let collectionView = collectionView, scrollView === collectionView,
            let width = collectionView.cellForItem(at: IndexPath(item: 0, section: 0))?.bounds.width else { return }
        
        for item in 0..<collectionView.numberOfItems(inSection: 0) where scrollView.contentOffset.x <= CGFloat(item) * (width + width/2) {
            let indexPath = IndexPath(item: item, section: 0)
            collectionView.scrollToItem(at: indexPath, at: .left, animated: true)
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! EpisodeCollectionViewCell
        
        let data = dataSource[indexPath.row]
        
        cell.titleLabel.text = "\(data.episode). \(data.title)"
        cell.subtitleLabel.text = DateFormatter.localizedString(from: data.firstAirDate, dateStyle: .medium, timeStyle: .none)
        
        if let image = data.smallBackgroundImage,
            let url = URL(string: image) {
            cell.imageView.af_setImage(withURL: url, placeholderImage: UIImage(named: "Episode Placeholder"), imageTransition: .crossDissolve(animationLength))
        } else {
            cell.imageView.image = UIImage(named: "Episode Placeholder")
        }
        
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, didChangeToSize size: CGSize) {
        let layout = collectionView.collectionViewLayout as! SeparatorCollectionViewLayout
        let itemSize = self.collectionView(collectionView, layout: layout, sizeForItemAt: IndexPath(item: 0, section: 0))
        
        let items = CGFloat(collectionView.numberOfItems(inSection: 0))
        let itemHeight = itemSize.height + layout.minimumInteritemSpacing // Account for the separator height.
        let estimatedHeight = itemHeight * items
        
        let maxSize = CGSize(width: size.width, height: itemHeight * 6)
        let size = CGSize(width: size.width, height: estimatedHeight)
        
        super.collectionView(collectionView, didChangeToSize: size.height <= maxSize.height ? size : maxSize)
    }
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = collectionView.bounds.width
        return CGSize(width: traitCollection.horizontalSizeClass == .regular ? width/2 : width, height: 55)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showEpisode",
            let cell = sender as? UICollectionViewCell,
            let indexPath = collectionView?.indexPath(for: cell),
            let vc = segue.destination as? EpisodeDetailViewController {
            vc.episode = dataSource[indexPath.row]
        }
    }
}
