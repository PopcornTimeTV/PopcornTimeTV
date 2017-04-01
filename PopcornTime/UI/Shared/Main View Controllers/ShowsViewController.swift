

import UIKit
import class PopcornKit.ShowManager
import func PopcornKit.loadShows

class ShowsViewController: MainViewController {
    
    var currentGenre = ShowManager.Genres.all {
        didSet {
            collectionViewController.currentPage = 1
            didRefresh(collectionView: collectionView!)
        }
    }
    var currentFilter = ShowManager.Filters.trending {
        didSet {
            collectionViewController.currentPage = 1
            didRefresh(collectionView: collectionView!)
        }
    }
    
    override func collectionView(nibForHeaderInCollectionView collectionView: UICollectionView) -> UINib? {
        return UINib(nibName: String(describing: ContinueWatchingCollectionReusableView.self), bundle: nil)
    }
    
    override func load(page: Int) {
        guard !collectionViewController.isLoading else { return }
        collectionViewController.isLoading = true
        collectionViewController.hasNextPage = false
        PopcornKit.loadShows(page, filterBy: currentFilter, genre: currentGenre) { [unowned self] (shows, error) in
            self.collectionViewController.isLoading = false
            
            guard let shows = shows else { self.collectionViewController.error = error; self.collectionView?.reloadData(); return }
            
            self.collectionViewController.dataSources[0] += shows as [AnyHashable]
            self.collectionViewController.dataSources[0].unique()
            
            if shows.isEmpty // If the array passed in is empty, there are no more results so the content inset of the collection view is reset.
            {
                self.collectionView?.contentInset.bottom = self.tabBarController?.tabBar.frame.height ?? 0
            } else {
                self.collectionViewController.hasNextPage = true
            }
            self.collectionView?.reloadData()
        }
    }
    
    @IBAction func showFilters(_ sender: Any) {
        let controller = UIAlertController(title: "Select a filter to sort by".localized, message: nil, preferredStyle: .actionSheet, blurStyle: .dark)
        
        let handler: ((UIAlertAction) -> Void) = { (handler) in
            self.currentFilter = ShowManager.Filters.array.first(where: {$0.string == handler.title!})!
        }
        
        ShowManager.Filters.array.forEach {
            controller.addAction(UIAlertAction(title: $0.string, style: .default, handler: handler))
        }
        
        controller.addAction(UIAlertAction(title: "Cancel".localized, style: .cancel, handler: nil))
        controller.preferredAction = controller.actions.first(where: {$0.title == self.currentFilter.string})
        
        if let barButtonItem = sender as? UIBarButtonItem {
            controller.popoverPresentationController?.barButtonItem = barButtonItem
        }
        
        present(controller, animated: true)
    }
    
    @IBAction func showGenres(_ sender: Any) {
        let controller = UIAlertController(title: "Select a genre to filter by".localized, message: nil, preferredStyle: .actionSheet, blurStyle: .dark)
        
        let handler: ((UIAlertAction) -> Void) = { (handler) in
            self.currentGenre = ShowManager.Genres.array.first(where: {$0.rawValue == handler.title!})!
            self.navigationItem.title = self.currentGenre == .all ? "Shows".localized : self.currentGenre.rawValue
        }
        
        ShowManager.Genres.array.forEach {
            controller.addAction(UIAlertAction(title: $0.rawValue, style: .default, handler: handler))
        }
        
        controller.addAction(UIAlertAction(title: "Cancel".localized, style: .cancel, handler: nil))
        controller.preferredAction = controller.actions.first(where: {$0.title == self.currentGenre.rawValue})
        
        if let barButtonItem = sender as? UIBarButtonItem {
            controller.popoverPresentationController?.barButtonItem = barButtonItem
        }
        
        present(controller, animated: true)
    }
}
