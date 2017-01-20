

import UIKit
import PopcornKit

class MoviesViewController: MainViewController {
    
    var currentGenre = MovieManager.Genres.all {
        didSet {
            didRefresh(collectionView: collectionView!)
        }
    }
    var currentFilter = MovieManager.Filters.trending {
        didSet {
            didRefresh(collectionView: collectionView!)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        WatchedlistManager<Movie>.movie.getWatched() { [unowned self] _ in
            self.collectionView!.reloadData()
        }
    }
    
    override func load(page: Int) {
        guard !collectionViewController.isLoading else { return }
        collectionViewController.isLoading = true
        collectionViewController.hasNextPage = false
        PopcornKit.loadMovies(page, filterBy: currentFilter, genre: currentGenre) { [unowned self] (movies, error) in
            self.collectionViewController.isLoading = false
            
            guard let movies = movies else { self.collectionViewController.error = error; self.collectionView?.reloadData(); return }
            
            self.collectionViewController.dataSource += movies as [AnyHashable]
            self.collectionViewController.dataSource.uniqued()
            
            if movies.isEmpty // If the array passed in is empty, there are no more results so the content inset of the collection view is reset.
            {
                self.collectionView?.contentInset.bottom -= self.collectionViewController.paginationIndicatorInset
            } else {
                self.collectionViewController.hasNextPage = true
            }
            self.collectionView?.reloadData()
        }
    }
    
    override func didSelectFilter(at index: Int) {
        currentFilter = MovieManager.Filters.array[index]
    }
    
    override func didSelectGenre(at index: Int) {
        currentGenre = MovieManager.Genres.array[index]
        navigationItem.title = currentGenre == .all ? "Movies" : currentGenre.rawValue
    }
    
    override func populateGenres(_ array: inout [String]) {
        array = MovieManager.Genres.array.map({$0.rawValue})
    }
}
