

import UIKit
import PopcornKit

class ShowsViewController: MainViewController {
    
    var currentGenre = ShowManager.Genres.all {
        didSet {
            didRefresh(collectionView: collectionView!)
        }
    }
    var currentFilter = ShowManager.Filters.trending {
        didSet {
            didRefresh(collectionView: collectionView!)
        }
    }
    
    override func load(page: Int) {
        guard !collectionViewController.isLoading else { return }
        collectionViewController.isLoading = true
        collectionViewController.hasNextPage = false
        PopcornKit.loadShows(page, filterBy: currentFilter, genre: currentGenre) { [unowned self] (shows, error) in
            self.collectionViewController.isLoading = false
            
            guard let shows = shows else { self.collectionViewController.error = error; self.collectionView?.reloadData(); return }
            
            self.collectionViewController.dataSource += shows as [AnyHashable]
            self.collectionViewController.dataSource.uniqued()
            
            if shows.isEmpty // If the array passed in is empty, there are no more results so the content inset of the collection view is reset.
            {
                self.collectionView?.contentInset.bottom -= self.collectionViewController.paginationIndicatorInset
            } else {
                self.collectionViewController.hasNextPage = true
            }
            self.collectionView?.reloadData()
        }
    }
    
    override func didSelectFilter(at index: Int) {
        currentFilter = ShowManager.Filters.array[index]
    }
    
    override func didSelectGenre(at index: Int) {
        currentGenre = ShowManager.Genres.array[index]
        navigationItem.title = currentGenre == .all ? "Movies" : currentGenre.rawValue
    }
    
    override func populateGenres(_ array: inout [String]) {
        array = ShowManager.Genres.array.map({$0.rawValue})
    }
}
