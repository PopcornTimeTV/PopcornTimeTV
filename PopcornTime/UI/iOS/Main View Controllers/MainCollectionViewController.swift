

import UIKit
import PopcornKit

class MainCollectionViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout, GenresDelegate, UISearchControllerDelegate, UISearchBarDelegate, UISearchResultsUpdating, UIPopoverPresentationControllerDelegate {
    
    func loadNextPage(_ page: Int, searchTerm: String? = nil, removeCurrentData: Bool = false) { fatalError("Must be overridden") }
    
    func populateDataSourceArray(_ array: inout [String]) { fatalError("Must be overridden") }
    
    func finished(_ genreArrayIndex: Int) { fatalError("Must be overridden") }
    
    let searchDelay: TimeInterval = 0.25
    var workItem: DispatchWorkItem?
    
    let cache = NSCache<AnyObject, UINavigationController>()
    
    private var classContext = 0
    
    var header: FilterCollectionReusableView?
    var media = [Media]()
    
    var error: NSError?
    var isLoading: Bool = false
    var hasNextPage: Bool = false
    var currentPage: Int = 1
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadNextPage(1)
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refresh(_:)), for: .valueChanged)
        collectionView?.addSubview(refreshControl)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        searchController.searchBar.isHidden = false
        searchController.searchBar.becomeFirstResponder()
        collectionView?.addObserver(self, forKeyPath: "frame", options: .new, context: &classContext)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        searchController.searchBar.isHidden = true
        searchController.searchBar.resignFirstResponder()
        collectionView?.removeObserver(self, forKeyPath: "frame")
    }
    
    // MARK: - Frame Updates
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        collectionView?.performBatchUpdates(nil, completion: nil)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if let keyPath = keyPath, keyPath == "frame" && context == &classContext {
            collectionView?.performBatchUpdates(nil, completion: nil)
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
    
    func refresh(_ sender: UIRefreshControl) {
        loadNextPage(1, searchTerm: searchController.searchBar.text, removeCurrentData: true)
        currentPage = 1
        sender.endRefreshing()
    }
    
    // MARK: - Bar buttons
    
    func filterDidChange(atIndex index: Int) { fatalError("Must be overridden") }
    
    @IBAction func segmentedControlDidChangeSegment(_ segmentedControl: UISegmentedControl) {
        filterDidChange(atIndex: segmentedControl.selectedSegmentIndex)
    }
    
    @IBAction func presentSearch() {
        present(searchController, animated: true, completion: nil)
    }
    
    @IBAction func showFilter() {
        collectionView?.performBatchUpdates({
            guard let header = self.header else { return }
            header.isHidden = !header.isHidden
        }, completion: nil)
    }
    
    @IBAction func showGenres(_ sender: UIBarButtonItem) {
        let vc = cache.object(forKey: self) ?? {
            let vc = storyboard?.instantiateViewController(withIdentifier: "GenresNavigationController") as! UINavigationController
            cache.setObject(vc, forKey: self)
            (vc.viewControllers.first as! GenresTableViewController).delegate = self
            vc.modalPresentationStyle = .popover
            vc.popoverPresentationController?.backgroundColor = UIColor(red: 30.0/255.0, green: 30.0/255.0, blue: 30.0/255.0, alpha: 1.0)
            return vc
        }()
        vc.popoverPresentationController?.barButtonItem = sender
        present(vc, animated: true, completion: nil)
    }
    
    // MARK: Scroll view delegate
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView == collectionView else { return }
        let y = scrollView.contentOffset.y + scrollView.bounds.size.height - scrollView.contentInset.bottom
        let height = scrollView.contentSize.height
        let reloadDistance: CGFloat = 10
        if y > height + reloadDistance && isLoading == false && hasNextPage == true {
            collectionView?.contentInset.bottom = 80
            let background = UIView(frame: collectionView!.bounds)
            let indicator = UIActivityIndicatorView(activityIndicatorStyle: .white)
            indicator.translatesAutoresizingMaskIntoConstraints = false
            indicator.startAnimating()
            background.addSubview(indicator)
            indicator.centerXAnchor.constraint(equalTo: background.centerXAnchor).isActive = true
            indicator.bottomAnchor.constraint(equalTo: background.bottomAnchor, constant: -55).isActive = true
            collectionView?.backgroundView = background
            currentPage += 1
            loadNextPage(currentPage, searchTerm: searchController.searchBar.text, removeCurrentData: false)
        }
    }
    
    // MARK: - Collection view flow layout delegate
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout,sizeForItemAt indexPath: IndexPath) -> CGSize {
        var width = (collectionView.bounds.width/CGFloat(2))-8
        if traitCollection.horizontalSizeClass == .regular
        {
            var items = 1
            while (collectionView.bounds.width/CGFloat(items))-8 > 195 {
                items += 1
            }
            width = (collectionView.bounds.width/CGFloat(items))-8
        }
        let ratio = width/195.0
        let height = 280.0 * ratio
        return CGSize(width: width, height: height)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        guard let header = header, !header.isHidden else { return CGSize.min }
        return CGSize(width: view.frame.size.width, height: 50)
    }
    
    // MARK: - Collection view data source
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return media.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! CoverCollectionViewCell
        let media = self.media[indexPath.row]
        cell.titleLabel.text = media.title
        if let year = (media as? Show)?.year ?? (media as? Movie)?.year {
            cell.yearLabel.text = year
        }
        if let image = media.mediumCoverImage,
            let url = URL(string: image) {
            cell.coverImage.af_setImage(withURL: url, placeholderImage: UIImage(named: "\((media is Movie) ? "Movie" : "Episode") Placeholder"), imageTransition: .crossDissolve(animationLength))
        }
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        header = header ?? {
            let reuseableView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "filter", for: indexPath) as! FilterCollectionReusableView
            reuseableView.segmentedControl?.removeAllSegments()
            let array: [String]
            
            if type(of: self) == MoviesCollectionViewController.self {
                array = MovieManager.Filters.array.map({$0.string})
            } else if type(of: self) == ShowsCollectionViewController.self {
                array = ShowManager.Filters.array.map({$0.string})
            } else if type(of: self) == AnimeCollectionViewController.self {
                array = AnimeManager.Filters.array.map({$0.string})
            } else { array = [String]() }
            
            for (index, filterValue) in array.enumerated() {
                reuseableView.segmentedControl?.insertSegment(withTitle: filterValue, at: index, animated: false)
            }
            reuseableView.isHidden = true
            reuseableView.segmentedControl?.addTarget(self, action: #selector(segmentedControlDidChangeSegment(_:)), for: .valueChanged)
            reuseableView.segmentedControl?.selectedSegmentIndex = 0
            return reuseableView
        }()
        return header!
    }
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        collectionView.backgroundView = nil
        guard media.isEmpty else { return 1 }
        if let error = error {
            let background = Bundle.main.loadNibNamed("TableBackgroundView", owner: self, options: nil)?.first as! TableBackgroundView
            background.setUpView(error: error)
            collectionView.backgroundView = background
        } else if isLoading {
            let indicator = UIActivityIndicatorView(activityIndicatorStyle: .white)
            indicator.center = collectionView.center
            collectionView.backgroundView = indicator
            indicator.sizeToFit()
            indicator.startAnimating()
        } else {
            let background = Bundle.main.loadNibNamed("TableBackgroundView", owner: self, options: nil)?.first as! TableBackgroundView
            background.setUpView(image: UIImage(named: "Search")!, title: "No results found.", description: "No search results found for \(searchController.searchBar.text!). Please check the spelling and try again.")
            collectionView.backgroundView = background
        }
        return 1
    }
    
    func refreshData() {
        media.removeAll()
        collectionView?.reloadData()
        currentPage = 1
        loadNextPage(currentPage, searchTerm: searchController.searchBar.text)
    }
    
    // MARK: - Searching
    
    func didDismissSearchController(_ searchController: UISearchController) {
        refreshData()
    }
    
    lazy var searchController: UISearchController = {
        let svc = UISearchController(searchResultsController: nil)
        svc.searchResultsUpdater = self
        svc.delegate = self
        svc.searchBar.delegate = self
        svc.searchBar.barStyle = .black
        svc.searchBar.isTranslucent = false
        svc.hidesNavigationBarDuringPresentation = false
        svc.dimsBackgroundDuringPresentation = false
        svc.searchBar.keyboardAppearance = .dark
        return svc
    }()
    
    func updateSearchResults(for searchController: UISearchController) {
        workItem?.cancel()
        
        workItem = DispatchWorkItem {
            self.refreshData()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + searchDelay, execute: workItem!)
    }
}

extension UISearchController {
    open override var preferredStatusBarStyle : UIStatusBarStyle {
        // Fixes status bar color changing from black to white upon presentation.
        return .lightContent
    }
}
