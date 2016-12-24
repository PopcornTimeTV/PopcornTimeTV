

import UIKit
import AlamofireImage
import PopcornKit

class AnimeCollectionViewController: MainCollectionViewController {
    
    var currentGenre = AnimeManager.Genres.all {
        didSet {
            refreshData()
        }
    }
    var currentFilter = AnimeManager.Filters.popularity {
        didSet {
            refreshData()
        }
    }
    
    override func loadNextPage(_ pageNumber: Int, searchTerm: String? = nil, removeCurrentData: Bool = false) {
        guard !isLoading else { return }
        isLoading = true
        hasNextPage = false
        PopcornKit.loadAnime(pageNumber, filterBy: currentFilter, genre: currentGenre, searchTerm: searchTerm, completion: { (anime, error) in
            self.isLoading = false
            guard let anime = anime else { self.error = error; self.collectionView?.reloadData(); return }
            if removeCurrentData { self.media.removeAll() }
            self.media += anime as [Media]
            self.media = unique(source: self.media as! [Show]) // Remove duplicates
            
            if anime.isEmpty // If the array passed in is empty, there are no more results so the content inset of the collection view is reset.
            {
                self.collectionView?.contentInset.bottom = 0.0
            } else {
                self.hasNextPage = true
            }
            self.collectionView?.reloadData()
        })
    }

    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showDetail",
            let destination = segue.destination as? ShowContainerViewController,
            let cell = sender as? CoverCollectionViewCell,
            let index = collectionView?.indexPath(for: cell)?.row,
            let anime = media[index] as? Show {
            destination.currentItem = anime
            destination.currentType = .animes
        }
    }
    
    override func filterDidChange(atIndex index: Int) {
        currentFilter = AnimeManager.Filters.array[index]
    }
    
    // MARK: - GenresDelegate
    
    override func finished(_ genreArrayIndex: Int) {
        navigationItem.title = AnimeManager.Genres.array[genreArrayIndex].rawValue
        if AnimeManager.Genres.array[genreArrayIndex] == .all {
            navigationItem.title = "Anime"
        }
        currentGenre = AnimeManager.Genres.array[genreArrayIndex]
    }
    
    override func populateDataSourceArray(_ array: inout [String]) {
        array = AnimeManager.Genres.array.map({$0.rawValue})
    }
}
