

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
            self.collectionViewController.dataSources[0] = updated.sorted(by: {$0.0.title < $0.1.title})
        }.sorted(by: {$0.0.title < $0.1.title})]
        
        collectionViewController.dataSources.append(WatchlistManager<Show>.show.getWatchlist { [unowned self] (updated) in
            self.collectionViewController.dataSources[1] = updated.sorted(by: {$0.0.title < $0.1.title})
        }.sorted(by: {$0.0.title < $0.1.title}))
    }
    
    override func collectionView(_ collectionView: UICollectionView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "Movies"
        } else if section == 1 {
            return "Shows"
        }
        return nil
    }
    
    override func collectionView(_ collectionView: UICollectionView, insetForSectionAt section: Int) -> UIEdgeInsets? {
        let isTv = UIDevice.current.userInterfaceIdiom == .tv
        
        return isTv ? UIEdgeInsets(top: 60, left: 90, bottom: 0, right: 90) : UIEdgeInsets(top: 5, left: 15, bottom: 15, right: 15)
    }
    
    override func collectionView(isEmptyForUnknownReason collectionView: UICollectionView) {
        if let background: ErrorBackgroundView = .fromNib() {
            background.setUpView(title: "Watchlist Empty", description: "Try adding movies or shows to your watchlist.")
            collectionView.backgroundView = background
        }
    }
}
