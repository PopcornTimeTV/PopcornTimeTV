

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
    
    override func load(page: Int) {
        filterSearchText(searchBar?.text ?? "")
    }
        
    override func minItemSize(forCellIn collectionView: UICollectionView, at indexPath: IndexPath) -> CGSize? {
        // Tweaked the cell size, to prevent the inability to reach the searchViewController
        if UIDevice.current.userInterfaceIdiom == .tv {
//            return CGSize(width: 250, height: fetchType == .people ? 400 : 460)
            return CGSize(width: 250, height: fetchType == .people ? 400 : 445) // Decreasing to 445 from 460 seems to do the trick!?
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
            if data!.count > 0 && data!.count < 3 {
                var newData = data
                // Add dummy results as a hack - Needs at least three items to allow selction
                for _ in 1...3 - data!.count {
                    newData?.append(PopcornKit.Movie(title: "DON'T OPEN!", id: "tt4654462", tmdbId: nil, slug: "dummyCell", summary: "Dummy provider - do not select!", torrents: [], subtitles: [:], largeBackgroundImage: nil, largeCoverImage: "https://www.freeiconspng.com/uploads/do-not-sign-icon-png-4.png"))
                }
                self.collectionViewController.dataSources = [newData!]

            } else {
                self.collectionViewController.dataSources = [data ?? []]
            }
            self.collectionViewController.error = error
            self.collectionViewController.isLoading = false
            self.collectionView?.reloadData()
        }
        
        switch fetchType {
        case .movies:
            PopcornKit.loadMovies(searchTerm: text) {arg1,arg2 in
                completion(arg1, arg2)
            }
        case .shows:
            PopcornKit.loadShows(searchTerm: text) {arg1,arg2 in
                completion(arg1, arg2)
            }
        case .people:
            TraktManager.shared.search( forPerson: text) {arg1,arg2 in
                completion(arg1 as! [Crew], arg2)
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
