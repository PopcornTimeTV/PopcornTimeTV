

import UIKit
import PopcornKit

class WatchlistViewController: MainViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionViewController.paginated = false
    }
    
    override func load(page: Int) {
        collectionViewController.dataSource += WatchlistManager<Movie>.movie.getWatchlist { (updated) in
            
        } as [AnyHashable]
        
        collectionViewController.dataSource += WatchlistManager<Show>.show.getWatchlist { (updated) in
            
        } as [AnyHashable]
    }
    
    override func collectionView(isEmptyForUnknownReason collectionView: UICollectionView) {
        // TODO: Empty UI
    }
}
