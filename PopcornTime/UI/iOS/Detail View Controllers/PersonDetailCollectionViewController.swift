

import Foundation
import PopcornKit

class PersonDetailCollectionViewController: MainViewController {
    
    var currentItem: Person!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = currentItem.name
        collectionViewController.paginated = false
    }
    
    override func load(page: Int) {
        guard !collectionViewController.isLoading else { return }
        collectionViewController.isLoading = true
        let group = DispatchGroup()
        
        let completion: ([AnyHashable], NSError?) -> Void = { [unowned self] (data, error) in
            self.collectionViewController.dataSource += data
            self.collectionViewController.error = error
            group.leave()
        }
        
        group.enter()
        TraktManager.shared.getMediaCredits(forPersonWithId: currentItem.imdbId, mediaType: Show.self) {
            completion($0.0, $0.1)
        }
        
        group.enter()
        TraktManager.shared.getMediaCredits(forPersonWithId: currentItem.imdbId, mediaType: Movie.self) {
            completion($0.0, $0.1)
        }
        
        group.notify(queue: .main) { [unowned self] in
            self.collectionViewController.isLoading = false
            self.collectionView?.reloadData()
        }
    }
}
