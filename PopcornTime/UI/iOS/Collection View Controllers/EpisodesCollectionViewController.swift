

import Foundation
import AlamofireImage
import struct PopcornKit.Episode

class EpisodesCollectionViewController: ResponsiveCollectionViewController, UICollectionViewDelegateFlowLayout, UIViewControllerTransitioningDelegate {
    
    var dataSource: [Episode] = []
    let interactor = EpisodeDetailPercentDrivenInteractiveTransition()
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        collectionView?.reloadData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView?.decelerationRate = UIScrollViewDecelerationRateFast
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! EpisodeCollectionViewCell
        
        let episode = dataSource[indexPath.row]
        
        let episodeNumber = NumberFormatter.localizedString(from: NSNumber(value: episode.episode), number: .none)
        cell.titleLabel.text = "\(episodeNumber). \(episode.title)"
        cell.subtitleLabel?.text = DateFormatter.localizedString(from: episode.firstAirDate, dateStyle: .medium, timeStyle: .none)
        cell.id = episode.id
        
        if let image = episode.smallBackgroundImage,
            let url = URL(string: image) {
            cell.imageView.af_setImage(withURL: url, placeholderImage: UIImage(named: "Episode Placeholder"), imageTransition: .crossDissolve(.default))
        } else {
            cell.imageView.image = UIImage(named: "Episode Placeholder")
        }
        
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, layout: UICollectionViewFlowLayout, didChangeToSize size: CGSize) {
        let layout = layout as! SeparatorCollectionViewLayout
        
        var estimatedContentHeight: CGFloat = 0.0
            
        let numberOfCells = CGFloat(collectionView.numberOfItems(inSection: 0))
        
        let itemSize = self.collectionView(collectionView, layout: layout, sizeForItemAt: IndexPath(item: 0, section: 0))
        let itemHeight = (itemSize.height + layout.minimumInteritemSpacing)
        estimatedContentHeight = itemHeight * numberOfCells
        
        let maxSize = CGSize(width: size.width, height: itemHeight * 6)
        let size = CGSize(width: size.width, height: estimatedContentHeight)
        
        super.collectionView(collectionView, layout: layout, didChangeToSize: size.height <= maxSize.height ? size : maxSize)
    }
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let inset = collectionView.contentInset
        let spacing = (collectionViewLayout as! UICollectionViewFlowLayout).minimumLineSpacing
        let width = collectionView.bounds.width - inset.left - inset.right - spacing
        return CGSize(width: traitCollection.horizontalSizeClass == .regular ? width/2 : width, height: 55)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showEpisode",
            let cell = sender as? UICollectionViewCell,
            let indexPath = collectionView?.indexPath(for: cell),
            let vc = segue.destination as? EpisodeDetailViewController {
            vc.episode = dataSource[indexPath.row]
            vc.transitioningDelegate = self
            vc.modalPresentationStyle = .custom
            vc.interactor = interactor
        }
    }
    
    // MARK: - Presentation
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        if presented is EpisodeDetailViewController {
            return EpisodeDetailAnimatedTransitioning(isPresenting: true)
        }
        return nil
        
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        if dismissed is EpisodeDetailViewController {
            return EpisodeDetailAnimatedTransitioning(isPresenting: false)
        }
        return nil
    }
    
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        return presented is EpisodeDetailViewController ? EpisodeDetailPresentationController(presentedViewController: presented, presenting: presenting) : nil
    }
    
    func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        if animator is EpisodeDetailAnimatedTransitioning && interactor.hasStarted  {
            return interactor
        }
        return nil
    }
}
