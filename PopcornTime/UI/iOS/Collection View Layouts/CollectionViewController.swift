

import Foundation
import PopcornKit

protocol CollectionViewControllerDelegate: class {
    func load(page: Int)
    func didRefresh(collectionView: UICollectionView)
    func collectionView(isEmptyForUnknownReason collectionView: UICollectionView)
}

extension CollectionViewControllerDelegate {
    func load(page: Int) {}
    func didRefresh(collectionView: UICollectionView) {}
    func collectionView(isEmptyForUnknownReason collectionView: UICollectionView) {}
}

class CollectionViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    
    var dataSource: [AnyHashable] = []
    var error: NSError?
    
    var paginationIndicatorInset: CGFloat = 20
    
    var isLoading: Bool = false
    var paginated: Bool = false
    weak var delegate: CollectionViewControllerDelegate?
    var hasNextPage: Bool = false
    var currentPage: Int = 1
    private var classContext = 0
    
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
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        collectionView?.performBatchUpdates(nil, completion: nil)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        var width = (view.bounds.width/2) - 8
        
        if traitCollection.horizontalSizeClass == .regular {
            var items: CGFloat = 1
            while (view.bounds.width/items) - 8 > 162.0 {
                items += 1
            }
            width = (view.bounds.width/items) - 8
        }
        
        let ratio = width/162.0
        let height = (dataSource[indexPath.row] is Person ? 190.0 : 275.0) * ratio
        
        return CGSize(width: width, height: height)
    }
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        collectionView.backgroundView = nil
        guard dataSource.isEmpty else { return 1 }
        
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
        return dataSource.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell: UICollectionViewCell
        let media = dataSource[indexPath.row]
        
        if let media = media as? Media {
            let identifier  = media is Movie ? "movieCell" : "showCell"
            let placeholder = media is Movie ? "Movie Placeholder" : "Episode Placeholder"
            
            let _cell = collectionView.dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath) as! CoverCollectionViewCell
            _cell.titleLabel.text = media.title
            _cell.watched = WatchedlistManager<Movie>.movie.isAdded(media.id) // Shows not supported for watched list
            
            if let image = media.mediumCoverImage,
                let url = URL(string: image) {
                _cell.coverImageView.af_setImage(withURL: url, placeholderImage: UIImage(named: placeholder), imageTransition: .crossDissolve(animationLength))
            } else {
                _cell.coverImageView = nil
            }
            
            cell = _cell
        } else if let person = media as? Person {
            let _cell = collectionView.dequeueReusableCell(withReuseIdentifier: "personCell", for: indexPath) as! MonogramCollectionViewCell
            _cell.titleLabel.text = person.name
            _cell.initialsLabel.text = person.initials
            
            if let image = person.mediumImage,
                let url = URL(string: image) {
                _cell.headshotImageView.af_setImage(withURL: url, imageTransition: .crossDissolve(animationLength))
            } else {
                _cell.headshotImageView = nil
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
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if let keyPath = keyPath, keyPath == "frame" && context == &classContext {
            collectionView?.performBatchUpdates(nil, completion: nil)
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refresh(_:)), for: .valueChanged)
        
        if #available(iOS 10.0, *) {
            collectionView?.refreshControl = refreshControl
        } else {
            collectionView?.addSubview(refreshControl)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        collectionView?.addObserver(self, forKeyPath: "frame", options: .new, context: &classContext)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        collectionView?.removeObserver(self, forKeyPath: "frame")
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let identifier = segue.identifier,
            let cell = sender as? UICollectionViewCell,
            let indexPath = collectionView?.indexPath(for: cell) {
            
            if identifier == "showMovie",
                let vc = segue.destination as? MovieDetailViewController,
                let movie = dataSource[indexPath.row] as? Movie {
                vc.currentItem = movie
            } else if identifier == "showShow",
                let vc = segue.destination as? ShowContainerViewController,
                let show = dataSource[indexPath.row] as? Show {
                vc.currentItem = show
            } else if identifier == "showPerson",
                let vc = segue.destination as? PersonDetailCollectionViewController,
                let person = dataSource[indexPath.row] as? Person {
                vc.currentItem = person
            }
        }
    }
}
