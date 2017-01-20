

import UIKit
import AlamofireImage
import PopcornKit

class SearchViewController: UIViewController, UISearchBarDelegate, UIToolbarDelegate, CollectionViewControllerDelegate {
    
    @IBOutlet var searchBar: UISearchBar!
    @IBOutlet var toolbar: UIToolbar!
    @IBOutlet var segmentedControl: UISegmentedControl!
    
    
    let searchDelay: TimeInterval = 0.25
    var workItem: DispatchWorkItem!
    
    var fetchType: Trakt.MediaType = .movies
    
    var collectionViewController: CollectionViewController!
    
    var collectionView: UICollectionView? {
        get {
            return collectionViewController.collectionView
        } set(newObject) {
            collectionViewController.collectionView = newObject
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.isHairlineHidden = true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        searchBar.keyboardAppearance = .dark
        collectionView?.contentInset.top = toolbar.frame.height
        collectionView?.contentInset.bottom = tabBarController?.tabBar.frame.height ?? 0
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        segmentedControl.frame.origin.x = searchBar.frame.origin.x
        segmentedControl.frame.size.width = searchBar.frame.width
    }
    
    @IBAction func segmentedControlDidChangeSegment(_ segmentedControl: UISegmentedControl) {
        switch segmentedControl.selectedSegmentIndex {
        case 0:
            fetchType = .movies
        case 1:
            fetchType = .shows
        case 2:
            fetchType = .people
        default: return
        }
        
        filterSearchText(searchBar.text ?? "")
    }
    
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        searchBar.showsCancelButton = true
        return true
    }
    
    func searchBarShouldEndEditing(_ searchBar: UISearchBar) -> Bool {
        searchBar.showsCancelButton = false
        return true
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        workItem?.cancel()
        
        workItem = DispatchWorkItem {
            self.filterSearchText(searchText)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + searchDelay, execute: workItem)
    }
    
    func filterSearchText(_ text: String) {
        guard !text.isEmpty else {
            collectionViewController.dataSource.removeAll()
            collectionView?.reloadData()
            return
        }
        
        let completion: ([AnyHashable]?, NSError?) -> Void = { [unowned self] (data, error) in
            self.collectionViewController.dataSource = data ?? []
            self.collectionViewController.error = error
            self.collectionView?.reloadData()
        }
        
        switch fetchType {
        case .movies:
            PopcornKit.loadMovies(searchTerm: text) {
                completion($0.0, $0.1)
            }
        case .shows:
            PopcornKit.loadShows(searchTerm: text) {
                completion($0.0, $0.1)
            }
        case .people:
            TraktManager.shared.search(forPerson: text) {
                completion($0.0 as! [Crew], $0.1)
            }
        default:
            return
        }
    }
    
    func collectionView(isEmptyForUnknownReason collectionView: UICollectionView) {
        if let background: ErrorBackgroundView = .fromNib(),
            let image = UIImage(named: "No Search Results"), let text = searchBar.text, !text.isEmpty {
            background.setUpView(image: image, title: "No Results", description: "We didn't turn up anything for \"\(text)\". Try something else.")
            collectionView.backgroundView = background
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "embed", let vc = segue.destination as? CollectionViewController {
            collectionViewController = vc
            collectionViewController.delegate = self
        }
    }
    
    func position(for bar: UIBarPositioning) -> UIBarPosition {
        return .topAttached
    }
}
