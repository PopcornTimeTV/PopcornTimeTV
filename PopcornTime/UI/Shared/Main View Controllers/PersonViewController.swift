

import Foundation
import PopcornKit

class PersonViewController: MainViewController {
    
    var currentItem: Person!
    
    // tvOS Exclusive
    
    @IBOutlet var titleLabel: UILabel?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = currentItem.name
        titleLabel?.text = currentItem.name
        collectionViewController.paginated = false
    }
    
    override func load(page: Int) {
        guard !collectionViewController.isLoading else { return }
        collectionViewController.isLoading = true
        let group = DispatchGroup()
        
        let completion: ([AnyHashable], NSError?) -> Void = { [unowned self] (data, error) in
            self.collectionViewController.dataSources[0] += data
            self.collectionViewController.dataSources[0].unique()
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
    
    override func collectionView(isEmptyForUnknownReason collectionView: UICollectionView) {
        if let background: ErrorBackgroundView = .fromNib() {
            let openQuote = Locale.current.quotationBeginDelimiter ?? "\""
            let closeQuote = Locale.current.quotationEndDelimiter ?? "\""
            
            background.setUpView(title: "No results".localized, description: String.localizedStringWithFormat("We didn't turn anything up for %@. Try something else.", "\(openQuote + currentItem.name + closeQuote)"))
            
            collectionView.backgroundView = background
        }
    }
}
