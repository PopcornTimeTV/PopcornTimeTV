

import Foundation
import PopcornKit
import CSStickyHeaderFlowLayout

protocol CollectionViewControllerDelegate: class {
    func load(page: Int)
    func didRefresh(collectionView: UICollectionView)
    func collectionView(isEmptyForUnknownReason collectionView: UICollectionView)
    
    func collectionView(_ collectionView: UICollectionView, titleForHeaderInSection section: Int) -> String?
    func collectionView(nibForHeaderInCollectionView collectionView: UICollectionView) -> UINib?
    
    func minItemSize(forCellIn collectionView: UICollectionView, at indexPath: IndexPath) -> CGSize?
}

extension CollectionViewControllerDelegate {
    func load(page: Int) {}
    func didRefresh(collectionView: UICollectionView) {}
    func collectionView(isEmptyForUnknownReason collectionView: UICollectionView) {}
    
    func collectionView(_ collectionView: UICollectionView, titleForHeaderInSection section: Int) -> String? { return nil }
    func collectionView(nibForHeaderInCollectionView collectionView: UICollectionView) -> UINib? { return nil }
    
    func minItemSize(forCellIn collectionView: UICollectionView, at indexPath: IndexPath) -> CGSize? { return nil }
}

class CollectionViewController: ResponsiveCollectionViewController, UICollectionViewDelegateFlowLayout {
    
    var dataSources: [[AnyHashable]] = [[]]
    var error: NSError?
    
    var paginationIndicatorInset: CGFloat {
        return UIDevice.current.userInterfaceIdiom == .tv ? 0 : 5
    }
    
    func minItemSize(forCellIn collectionView: UICollectionView, at indexPath: IndexPath) -> CGSize {
        if let size = delegate?.minItemSize(forCellIn: collectionView, at: indexPath) {
            return size
        } else {
            return UIDevice.current.userInterfaceIdiom == .tv ? CGSize(width: 250, height: 460) : CGSize(width: 108, height: 185)
        }
    }
    
    var isLoading = false
    var paginated = false
    weak var delegate: CollectionViewControllerDelegate?
    var hasNextPage = false
    var currentPage = 1
    
    var activeRootViewController: MainViewController? {
        return (UIApplication.shared.delegate as! AppDelegate).activeRootViewController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let collectionView = collectionView, let layout = collectionView.collectionViewLayout as? CSStickyHeaderFlowLayout {
            if let nib = delegate?.collectionView(nibForHeaderInCollectionView: collectionView) {
                let size = CGSize(width: collectionView.bounds.width, height: 0)
                layout.parallaxHeaderReferenceSize = size
                layout.parallaxHeaderMinimumReferenceSize = size
                layout.disableStickyHeaders = true
                layout.disableStretching = true
                
                collectionView.register(nib, forSupplementaryViewOfKind: CSStickyHeaderParallaxHeader, withReuseIdentifier: "stickyHeader")
            } else {
                layout.sectionHeadersPinToVisibleBounds = true
            }
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, layout: UICollectionViewFlowLayout, didChangeToSize size: CGSize) {
        let itemSize = self.collectionView(collectionView, layout: layout, sizeForItemAt: IndexPath(item: 0, section: 0))
        super.collectionView(collectionView, layout: layout, didChangeToSize: CGSize(width: size.width, height: itemSize.height))
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        guard let flowLayout = collectionViewLayout as? UICollectionViewFlowLayout else { return .zero }
        
        let minItemSize = self.minItemSize(forCellIn: collectionView, at: indexPath)
        
        var width: CGFloat = 0
        let sectionInset = flowLayout.sectionInset.left + flowLayout.sectionInset.right
        let spacing = flowLayout.scrollDirection == .horizontal ? flowLayout.minimumLineSpacing : flowLayout.minimumInteritemSpacing
        
        for items in (2...Int.max) {
            let items = CGFloat(items)
            let newWidth = (view.bounds.width/items) - (sectionInset/items) - (spacing * (items - 1)/items)
            if newWidth < minItemSize.width && items > 2 // Minimum of 2 cells no matter the screen size
            {
                break
            }
            width = newWidth
        }
        
        let ratio = width/minItemSize.width
        let height = minItemSize.height * ratio
        
        return CGSize(width: width, height: height)
    }
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        collectionView.backgroundView = nil
        guard dataSources.flatMap({$0}).isEmpty else {
            error = nil
            return dataSources.count
        }
        
        if let error = error,
            let background: ErrorBackgroundView = .fromNib() {
            background.setUpView(error: error)
            collectionView.backgroundView = background
        } else if isLoading {
            let view: LoadingView? = .fromNib()
            collectionView.backgroundView = view
            view?.sizeToFit()
        } else {
            delegate?.collectionView(isEmptyForUnknownReason: collectionView)
        }
        
        return 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataSources[safe: section]?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return delegate?.collectionView(collectionView, titleForHeaderInSection: section) != nil && collectionView.numberOfItems(inSection: section) != 0 ? CGSize(width: collectionView.bounds.width, height: 40) : .zero
    }
    
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionElementKindSectionHeader, let title = delegate?.collectionView(collectionView, titleForHeaderInSection: indexPath.section) {
            let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "sectionHeader", for: indexPath)
            
            let label = header.viewWithTag(1) as? UILabel
            label?.text = title
            
            return header
        } else if kind == CSStickyHeaderParallaxHeader {
            let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "stickyHeader", for: indexPath) as! ContinueWatchingCollectionReusableView
            if let parent = parent {
                header.type = type(of: parent) == MoviesViewController.self ? .movies : .episodes
                header.refreshOnDeck()
            }
            return header
        }
        return super.collectionView(collectionView, viewForSupplementaryElementOfKind: kind, at: indexPath)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        return .zero
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        let isTv = UIDevice.current.userInterfaceIdiom == .tv
        return dataSources[safe: section]?.isEmpty ?? true ? .zero : isTv ? UIEdgeInsets(top: 60, left: 90, bottom: 60, right: 90) : UIEdgeInsets(top: 15, left: 15, bottom: 15, right: 15)
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell: UICollectionViewCell
        let media = dataSources[indexPath.section][indexPath.row]
        
        if let media = media as? Media {
            let identifier  = media is Movie ? "movieCell" : "showCell"
            let placeholder = media is Movie ? "Movie Placeholder" : "Episode Placeholder"
            
            let _cell = collectionView.dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath) as! CoverCollectionViewCell
            _cell.titleLabel.text = media.title
            _cell.watched = media.isWatched
            
            #if os(tvOS)
                _cell.hidesTitleLabelWhenUnfocused = true
            #endif
            
            if let image = media.smallCoverImage,
                let url = URL(string: image) {
                _cell.imageView.af_setImage(withURL: url, placeholderImage: UIImage(named: placeholder), imageTransition: .crossDissolve(animationLength))
            } else {
                _cell.imageView.image = UIImage(named: placeholder)
            }
            
            cell = _cell
        } else if let person = media as? Person {
            let _cell = collectionView.dequeueReusableCell(withReuseIdentifier: "personCell", for: indexPath) as! MonogramCollectionViewCell
            _cell.titleLabel.text = person.name
            _cell.initialsLabel.text = person.initials
            
            if let image = person.mediumImage,
                let url = URL(string: image) {
                _cell.imageView.af_setImage(withURL: url,  placeholderImage: UIImage(named: "Other Placeholder"), imageTransition: .crossDissolve(animationLength))
            } else {
                _cell.imageView.image = nil
            }
            
            if let actor = person as? Actor {
                _cell.subtitleLabel.text = actor.characterName
            } else if let crew = person as? Crew {
                _cell.subtitleLabel.text = crew.job
            }
            
            if UIDevice.current.userInterfaceIdiom == .tv {
                _cell.subtitleLabel.text = _cell.subtitleLabel.text?.uppercased()
            }
            
            cell = _cell
        } else {
            fatalError("Unknown type in dataSource.")
        }
        
        return cell
    }
    
    override func targetViewController(forAction action: Selector, sender: Any?) -> UIViewController? {
        return activeRootViewController
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let cell = sender as? UICollectionViewCell,
            let indexPath = collectionView?.indexPath(for: cell) {
            let sender = dataSources[indexPath.section][indexPath.row]
            
            activeRootViewController?.prepare(for: segue, sender: sender)
        }
    }
}
