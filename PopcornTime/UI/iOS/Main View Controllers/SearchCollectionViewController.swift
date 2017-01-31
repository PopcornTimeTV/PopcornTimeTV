

import UIKit
import AlamofireImage
import PopcornKit

class SearchViewController: MainViewController, UISearchBarDelegate, UIToolbarDelegate {
    
    @IBOutlet var searchBar: UISearchBar!
    @IBOutlet var toolbar: UIToolbar!
    @IBOutlet var segmentedControl: UISegmentedControl!
    
    
    let searchDelay: TimeInterval = 0.25
    var workItem: DispatchWorkItem!
    
    var fetchType: Trakt.MediaType = .movies
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.isHairlineHidden = true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        searchBar.keyboardAppearance = .dark
        collectionView?.contentInset.top = toolbar.frame.height
        collectionViewController.paginated = false
        
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        segmentedControl.leadingAnchor.constraint(equalTo: toolbar.leadingAnchor, constant: 12.0).isActive = true
        segmentedControl.trailingAnchor.constraint(equalTo: toolbar.trailingAnchor, constant: -12.0).isActive = true
        segmentedControl.centerYAnchor.constraint(equalTo: toolbar.centerYAnchor).isActive = true
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
        
        collectionViewController.minItemSize.height = fetchType == .people ? 230 : 300
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
        collectionViewController.isLoading = !text.isEmpty
        collectionViewController.dataSource.removeAll()
        collectionView?.reloadData()
        
        if text.isEmpty { return }
        
        let completion: ([AnyHashable]?, NSError?) -> Void = { [unowned self] (data, error) in
            self.collectionViewController.dataSource = data ?? []
            self.collectionViewController.error = error
            self.collectionViewController.isLoading = false
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
    
    override func collectionView(isEmptyForUnknownReason collectionView: UICollectionView) {
        if let background: ErrorBackgroundView = .fromNib(),
            let text = searchBar.text, !text.isEmpty {
            background.setUpView(title: "No Results", description: "We didn't turn up anything for \"\(text)\". Try something else.")
            collectionView.backgroundView = background
        } else {
            /// TODO: Empty UI
        }
    }
    
    func position(for bar: UIBarPositioning) -> UIBarPosition {
        return .topAttached
    }
}
