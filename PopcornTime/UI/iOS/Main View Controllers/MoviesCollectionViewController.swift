

import UIKit
import AlamofireImage
import PopcornKit

class MoviesCollectionViewController: MainCollectionViewController {
    
    var currentGenre = MovieManager.Genres.all {
        didSet {
            refreshData()
        }
    }
    var currentFilter = MovieManager.Filters.trending {
        didSet {
            refreshData()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        WatchedlistManager<Movie>.movie.getWatched() { _ in
            self.collectionView?.reloadData()
        }
    }
    
    override func loadNextPage(_ pageNumber: Int, searchTerm: String? = nil, removeCurrentData: Bool = false) {
        guard !isLoading else { return }
        isLoading = true
        hasNextPage = false
        PopcornKit.loadMovies(pageNumber, filterBy: currentFilter, genre: currentGenre, searchTerm: searchTerm, completion: { (movies, error) in
            self.isLoading = false
            guard let movies = movies else { self.error = error; self.collectionView?.reloadData(); return }
            if removeCurrentData { self.media.removeAll() }
            self.media += movies as [Media]
            self.media = unique(source: self.media as! [Movie])  // Remove duplicates
            
            if movies.isEmpty // If the array passed in is empty, there are no more results so the content inset of the collection view is reset.
            {
                self.collectionView?.contentInset.bottom = 0.0
            } else {
                self.hasNextPage = true
            }
            self.collectionView?.reloadData()
        })
    }
    
    override func filterDidChange(atIndex index: Int) {
        currentFilter = MovieManager.Filters.array[index]
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showDetail",
            let destination = segue.destination as? MovieDetailViewController,
            let cell = sender as? CoverCollectionViewCell,
            let index = collectionView?.indexPath(for: cell)?.row,
            let movie = media[index] as? Movie {
            destination.currentItem = movie
        }
    }
    
    // MARK: - GenresDelegate
    
    override func finished(_ genreArrayIndex: Int) {
        navigationItem.title = MovieManager.Genres.array[genreArrayIndex].rawValue
        if MovieManager.Genres.array[genreArrayIndex] == .all {
            navigationItem.title = "Movies"
        }
        currentGenre = MovieManager.Genres.array[genreArrayIndex]
    }
    
    override func populateDataSourceArray(_ array: inout [String]) {
        array = MovieManager.Genres.array.map({$0.rawValue})
    }
}
