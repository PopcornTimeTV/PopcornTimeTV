

import UIKit
import AlamofireImage
import PopcornKit

class ShowsCollectionViewController: MainCollectionViewController {
    
    var currentGenre = ShowManager.Genres.all {
        didSet {
            refreshData()
        }
    }
    var currentFilter = ShowManager.Filters.trending {
        didSet {
            refreshData()
        }
    }
    
    override func loadNextPage(_ pageNumber: Int, searchTerm: String? = nil, removeCurrentData: Bool = false) {
        guard !isLoading else { return }
        isLoading = true
        hasNextPage = false
        PopcornKit.loadShows(pageNumber, filterBy: currentFilter, genre: currentGenre, searchTerm: searchTerm, completion: { (shows, error) in
            self.isLoading = false
            guard let shows = shows else { self.error = error; self.collectionView?.reloadData(); return }
            if removeCurrentData { self.media.removeAll() }
            self.media += shows as [Media]
            if shows.isEmpty // If the array passed in is empty, there are no more results so the content inset of the collection view is reset.
            {
                self.collectionView?.contentInset.bottom = 0.0
            } else {
                self.hasNextPage = true
            }
            self.collectionView?.reloadData()
        })
    }
    
    override func filterDidChange(atIndex index: Int) {
        currentFilter = ShowManager.Filters.array[index]
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showDetail",
            let destination = segue.destination as? ShowContainerViewController,
            let cell = sender as? CoverCollectionViewCell,
            let index = collectionView?.indexPath(for: cell)?.row,
            let show = media[index] as? Show {
            destination.currentItem = show
        }
    }
    
    // MARK: - GenresDelegate
    
    override func finished(_ genreArrayIndex: Int) {
        navigationItem.title = ShowManager.Genres.array[genreArrayIndex].rawValue
        if ShowManager.Genres.array[genreArrayIndex] == .all {
            navigationItem.title = "Shows"
        }
        currentGenre = ShowManager.Genres.array[genreArrayIndex]
    }
    
    override func populateDataSourceArray(_ array: inout [String]) {
        array = ShowManager.Genres.array.map({$0.rawValue})
    }
}

class ShowContainerViewController: UIViewController {
    
    var currentItem: Show!
    var currentType: Trakt.MediaType = .shows
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showDetail", let vc = (segue.destination as? UISplitViewController)?.viewControllers.first as? ShowDetailViewController {
            vc.currentItem = currentItem
            vc.currentType = currentType
            vc.parentTabBarController = tabBarController
            vc.parentNavigationController = navigationController
            navigationItem.rightBarButtonItems = vc.navigationItem.rightBarButtonItems
            vc.parentNavigationItem = navigationItem
        }
    }
}
