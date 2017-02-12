

import UIKit
import PopcornKit

class WatchlistViewController: MainViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionViewController.paginated = false
    }
    
    override func viewWillAppear(_ animated: Bool) {
        load(page: -1) // Refresh watchlsit
        super.viewWillAppear(animated)
    }
    
    override func load(page: Int) {
        collectionViewController.dataSource += WatchlistManager<Movie>.movie.getWatchlist { (updated) in
            
        } as [AnyHashable]
        
        collectionViewController.dataSource += WatchlistManager<Show>.show.getWatchlist { (updated) in
            
        } as [AnyHashable]
    }
    
    override func collectionView(_ collectionView: UICollectionView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "Shows"
        } else if section == 1 {
            return "Movies"
        }
        return nil
    }
    
    override func collectionView(isEmptyForUnknownReason collectionView: UICollectionView) {
        if let background: ErrorBackgroundView = .fromNib() {
            background.setUpView(title: "Watchlist Empty", description: "Try adding movies or shows to your watchlist.")
            collectionView.backgroundView = background
        }
    }
}
