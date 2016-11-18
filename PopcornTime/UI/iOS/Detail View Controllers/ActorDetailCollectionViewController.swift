

import Foundation
import PopcornKit

class ActorDetailCollectionViewController: MoviesCollectionViewController {
    
    var currentItem: Actor!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = currentItem.name
    }

    
    override func loadNextPage(_ pageNumber: Int, searchTerm: String?, removeCurrentData: Bool) {
        guard !isLoading else { return }
        isLoading = true
        hasNextPage = false
        
        TraktManager.shared.getMediaCredits(forPersonWithId: currentItem.imdbId, mediaType: Movie.self) { (movies, error) in
            self.isLoading = false
            guard !movies.isEmpty else { self.error = error; self.collectionView?.reloadData(); return }
            if removeCurrentData { self.media.removeAll() }
            self.media += movies as [Media]
            if movies.isEmpty // If the array passed in is empty, there are no more results so the content inset of the collection view is reset.
            {
                self.collectionView?.contentInset.bottom = 0.0
            } else {
                self.hasNextPage = true
            }
            self.collectionView?.reloadData()
        }
    }
}
