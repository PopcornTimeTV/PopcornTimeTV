

import UIKit
import AlamofireImage
import PopcornKit

class SearchViewController: MainViewController, UISearchBarDelegate {
    
    #if os(iOS)
    
    @IBOutlet var searchBar: UISearchBar!
    @IBOutlet var toolbar: UIToolbar!
    @IBOutlet var segmentedControl: UISegmentedControl!
    
    #elseif os(tvOS)
    
    var searchBar: UISearchBar!
    var searchController: UISearchController!
    var searchContainerViewController: UISearchContainerViewController?
    
    #endif

    let searchDelay: TimeInterval = 0.25
    var workItem: DispatchWorkItem!
    
    var fetchType: Trakt.MediaType = .movies
    
    
    override func minItemSize(forCellIn collectionView: UICollectionView, at indexPath: IndexPath) -> CGSize? {
        if UIDevice.current.userInterfaceIdiom == .tv {
            return CGSize(width: 250, height: fetchType == .people ? 400 : 460)
        } else {
            return CGSize(width: 108, height: fetchType == .people ? 160 : 185)
        }
    }
    
    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        switch selectedScope {
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
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        workItem?.cancel()
        
        workItem = DispatchWorkItem {
            self.filterSearchText(searchText)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + searchDelay, execute: workItem)
    }
    
    func filterSearchText(_ text: String) {
        collectionViewController.isLoading = !text.isEmpty
        collectionViewController.dataSources = [[]]
        collectionView?.reloadData()
        
        if text.isEmpty { return }
        
        let completion: ([AnyHashable]?, NSError?) -> Void = { [unowned self] (data, error) in
            self.collectionViewController.dataSources = [data ?? []]
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
            
            let openQuote = Locale.current.quotationBeginDelimiter ?? "\""
            let closeQuote = Locale.current.quotationEndDelimiter ?? "\""
            
            background.setUpView(title: "No results".localized, description: .localizedStringWithFormat("We didn't turn anything up for %@. Try something else.".localized, "\(openQuote + text + closeQuote)"))
            
            collectionView.backgroundView = background
        }
    }
}
