

import Foundation
import PopcornKit
import CSStickyHeaderFlowLayout

protocol CollectionViewControllerDelegate: class {
    func load(page: Int)
    func didRefresh(collectionView: UICollectionView)
    func collectionView(isEmptyForUnknownReason collectionView: UICollectionView)
    
    func collectionView(_ collectionView: UICollectionView, titleForHeaderInSection section: Int) -> String?
    func collectionView(nibForHeaderInCollectionView collectionView: UICollectionView) -> UINib?
}

extension CollectionViewControllerDelegate {
    func load(page: Int) {}
    func didRefresh(collectionView: UICollectionView) {}
    func collectionView(isEmptyForUnknownReason collectionView: UICollectionView) {}
    
    func collectionView(_ collectionView: UICollectionView, titleForHeaderInSection section: Int) -> String? { return nil }
    func collectionView(nibForHeaderInCollectionView collectionView: UICollectionView) -> UINib? { return nil }
}

class CollectionViewController: ResponsiveCollectionViewController, UICollectionViewDelegateFlowLayout {
    
    var dataSources: [[AnyHashable]] = [[]]
    var error: NSError?
    
    var paginationIndicatorInset: CGFloat = 5
    var minItemSize = CGSize(width: 180, height: 300)
    
    var isLoading = false
    var paginated = false
    var isRefreshable: Bool = false {
        didSet {
            if isRefreshable {
                refreshControl = refreshControl ?? {
                    let refreshControl = UIRefreshControl()
                    refreshControl.addTarget(self, action: #selector(refresh(_:)), for: .valueChanged)
                    if #available(iOS 10.0, *) {
                        collectionView?.refreshControl = refreshControl
                    } else {
                        collectionView?.addSubview(refreshControl)
                    }
                    return refreshControl
                }()
            } else {
                if #available(iOS 10.0, *) {
                    collectionView?.refreshControl = nil
                } else {
                    refreshControl?.removeFromSuperview()
                }
            }
            
        }
    }
    weak var delegate: CollectionViewControllerDelegate?
    var hasNextPage = false
    var currentPage = 1
    
    private var refreshControl: UIRefreshControl?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let collectionView = collectionView,
            let layout = collectionView.collectionViewLayout as? CSStickyHeaderFlowLayout {
            if let nib = delegate?.collectionView(nibForHeaderInCollectionView: collectionView) {
                let size = CGSize(width: collectionView.bounds.width, height: 200)
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
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView == collectionView, paginated else { return }
        let y = scrollView.contentOffset.y + scrollView.bounds.size.height - scrollView.contentInset.bottom
        let height = scrollView.contentSize.height
        let reloadDistance: CGFloat = 10
        if y > height + reloadDistance && !isLoading && hasNextPage {
            collectionView?.contentInset.bottom += paginationIndicatorInset
            
            let background = UIView(frame: collectionView!.bounds)
            let indicator = UIActivityIndicatorView(activityIndicatorStyle: .white)
            
            indicator.translatesAutoresizingMaskIntoConstraints = false
            indicator.startAnimating()
            background.addSubview(indicator)
            
            indicator.centerXAnchor.constraint(equalTo: background.centerXAnchor).isActive = true
            indicator.bottomAnchor.constraint(equalTo: background.bottomAnchor, constant: -55).isActive = true
            collectionView?.backgroundView = background
            
            currentPage += 1
            delegate?.load(page: currentPage)
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, layout: UICollectionViewFlowLayout, didChangeToSize size: CGSize) {
        let itemSize = self.collectionView(collectionView, layout: layout, sizeForItemAt: IndexPath(item: 0, section: 0))
        super.collectionView(collectionView, layout: layout, didChangeToSize: CGSize(width: size.width, height: itemSize.height))
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        guard let flowLayout = collectionViewLayout as? UICollectionViewFlowLayout else { return .zero }
        
        var items: CGFloat = 1
        var width: CGFloat = .greatestFiniteMagnitude
        let sectionInset = flowLayout.sectionInset.left + flowLayout.sectionInset.right
        while width > minItemSize.width {
            items += 1
            width = (view.bounds.width/items) - (sectionInset/items) - (flowLayout.minimumInteritemSpacing * (items - 1)/items)
        }
        
        let ratio = width/minItemSize.width
        let height = minItemSize.height * ratio
        
        return CGSize(width: width, height: height)
    }
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        collectionView.backgroundView = nil
        guard dataSources.flatMap({$0}).isEmpty else { return dataSources.count }
        
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
        return dataSources[safe: section]?.isEmpty ?? true ? .zero : UIEdgeInsets(top: 15, left: 15, bottom: 15, right: 15)
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell: UICollectionViewCell
        let media = dataSources[indexPath.section][indexPath.row]
        
        if let media = media as? Media {
            let identifier  = media is Movie ? "movieCell" : "showCell"
            let placeholder = media is Movie ? "Movie Placeholder" : "Episode Placeholder"
            
            let _cell = collectionView.dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath) as! CoverCollectionViewCell
            _cell.titleLabel.text = media.title
            _cell.watched = WatchedlistManager<Movie>.movie.isAdded(media.id) // Shows not supported for watched list
            
            if let image = media.smallCoverImage,
                let url = URL(string: image) {
                _cell.coverImageView.af_setImage(withURL: url, placeholderImage: UIImage(named: placeholder), imageTransition: .crossDissolve(animationLength))
            } else {
                _cell.coverImageView.image = nil
            }
            
            cell = _cell
        } else if let person = media as? Person {
            let _cell = collectionView.dequeueReusableCell(withReuseIdentifier: "personCell", for: indexPath) as! MonogramCollectionViewCell
            _cell.titleLabel.text = person.name
            _cell.initialsLabel.text = person.initials
            
            if let image = person.mediumImage,
                let url = URL(string: image) {
                _cell.headshotImageView.af_setImage(withURL: url,  placeholderImage: UIImage(named: "Other Placeholder"), imageTransition: .crossDissolve(animationLength))
            } else {
                _cell.headshotImageView.image = nil
            }
            
            if let actor = person as? Actor {
                _cell.subtitleLabel.text = actor.characterName
            } else if let crew = person as? Crew {
                _cell.subtitleLabel.text = crew.job
            }
            
            cell = _cell
        } else {
            fatalError("Unknown type in dataSource.")
        }
        
        return cell
    }
    
    @objc private func refresh(_ sender: UIRefreshControl) {
        currentPage = 1
        sender.endRefreshing()
        delegate?.didRefresh(collectionView: collectionView!)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        (collectionView?.collectionViewLayout as? UICollectionViewFlowLayout)?.minimumInteritemSpacing = traitCollection.horizontalSizeClass == .regular ? 30 : 10
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let identifier = segue.identifier,
            let cell = sender as? UICollectionViewCell,
            let indexPath = collectionView?.indexPath(for: cell) {
            
            if identifier == "showMovie" || identifier == "showShow",
                let media = dataSources[indexPath.section][indexPath.row] as? Media,
                let vc = storyboard?.instantiateViewController(withIdentifier: String(describing: DetailViewController.self)) as? DetailViewController {
                
                // Exact same storyboard UI is being used for both classes. This will enable subclass-specific functions however, stored instance variables cannot be created on either subclass because object_setClass does not initialise stored variables.
                object_setClass(vc, media is Movie ? MovieDetailViewController.self : ShowDetailViewController.self)
                navigationController?.navigationBar.isBackgroundHidden = true
                
                vc.loadMedia(id: media.id) { (media, error) in
                    guard let navigationController = self.navigationController,
                        navigationController.visibleViewController === segue.destination else { return }
                    
                    let transition = CATransition()
                    transition.duration = 0.5
                    transition.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
                    transition.type = kCATransitionFade
                    navigationController.view.layer.add(transition, forKey: nil)
                    
                    defer {
                        DispatchQueue.main.asyncAfter(deadline: .now() + transition.duration) {
                            var viewControllers = navigationController.viewControllers
                            let index = viewControllers.count - 2
                            viewControllers.remove(at: index)
                            navigationController.setViewControllers(viewControllers, animated: false)
                        }
                    }
                    
                    if let error = error {
                        let vc = UIViewController()
                        let view: ErrorBackgroundView? = .fromNib()
                        
                        view?.setUpView(error: error)
                        vc.view = view
                        
                        navigationController.pushViewController(vc, animated: false)
                    } else {
                        vc.currentItem = media
                        
                        navigationController.pushViewController(vc, animated: false)
                    }
                }
            } else if identifier == "showPerson",
                let vc = segue.destination as? PersonDetailCollectionViewController,
                let person = dataSources[indexPath.section][indexPath.row] as? Person {
                vc.currentItem = person
            }
        }
    }
}
