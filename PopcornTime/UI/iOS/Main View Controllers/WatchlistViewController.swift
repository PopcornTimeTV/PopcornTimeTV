

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
        collectionViewController.dataSources = [WatchlistManager<Movie>.movie.getWatchlist { [unowned self] (updated) in
            self.collectionViewController.dataSources[0] = updated
        }]
        
        collectionViewController.dataSources.append(WatchlistManager<Show>.show.getWatchlist { [unowned self] (updated) in
            self.collectionViewController.dataSources[1] = updated
        })
    }
    
    override func collectionView(_ collectionView: UICollectionView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "Movies"
        } else if section == 1 {
            return "Shows"
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
