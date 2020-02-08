

import UIKit
import func PopcornKit.loadMovies
import class PopcornKit.MovieManager

class MoviesViewController: MediaViewController {
    @IBOutlet weak var magnetLinkTextField: UISearchBar!
    
    override func collectionView(nibForHeaderInCollectionView collectionView: UICollectionView) -> UINib? {
        return UINib(nibName: String(describing: ContinueWatchingCollectionReusableView.self), bundle: nil)
    }
    
    var currentFilter: MovieManager.Filters = .trending {
        didSet {
            collectionViewController.currentPage = 1
            didRefresh(collectionView: collectionView!)
        }
    }
    
    @IBAction func showExternalTorrentWindow(_ sender: Any) {
        #if os(iOS)
            if(magnetLinkTextField.frame.origin.y<=0){
                UIView.animate(withDuration: 0.2, animations: {
                    self.magnetLinkTextField.frame = CGRect(x: self.magnetLinkTextField.frame.origin.x, y: self.topLayoutGuide.length, width: self.magnetLinkTextField.frame.size.width, height: self.magnetLinkTextField.frame.size.height)
                })
            }else{
                UIView.animate(withDuration: 0.2, animations: {
                    self.magnetLinkTextField.frame = CGRect(x: self.magnetLinkTextField.frame.origin.x, y: -61, width: self.magnetLinkTextField.frame.size.width, height: self.magnetLinkTextField.frame.size.height)
                })
                self.magnetLinkTextField.endEditing(true)
            }
        #else
            let storyboard = UIStoryboard.main
            let externalTorrentViewController = storyboard.instantiateViewController(withIdentifier: "LoadExternalTorrentViewController")
            navigationController?.push(externalTorrentViewController, animated: true)
        #endif
    }
    
    @IBAction func showFilters(_ sender: Any) {
        let controller = UIAlertController(title: "Select a filter to sort by".localized, message: nil, preferredStyle: .actionSheet, blurStyle: .dark)
        
        let handler: ((UIAlertAction) -> Void) = { (handler) in
            self.currentFilter = MovieManager.Filters.array.first(where: {$0.string == handler.title!})!
        }
        
        MovieManager.Filters.array.forEach {
            controller.addAction(UIAlertAction(title: $0.string, style: .default, handler: handler))
        }
        
        controller.addAction(UIAlertAction(title: "Cancel".localized, style: .cancel, handler: nil))
        controller.preferredAction = controller.actions.first(where: {$0.title == self.currentFilter.string})
        
        if let barButtonItem = sender as? UIBarButtonItem {
            controller.popoverPresentationController?.barButtonItem = barButtonItem
        }
        
        present(controller, animated: true)
    }
    
    override func load(page: Int) {
        guard !collectionViewController.isLoading else { return }
        collectionViewController.isLoading = true
        collectionViewController.hasNextPage = false
        PopcornKit.loadMovies(page, filterBy: currentFilter, genre: currentGenre) { [unowned self] (movies, error) in
            self.collectionViewController.isLoading = false
            
            guard let movies = movies else { self.collectionViewController.error = error; self.collectionView?.reloadData(); return }
            
            self.collectionViewController.dataSources[0] += movies as [AnyHashable]
            self.collectionViewController.dataSources[0].unique()
            
            if movies.isEmpty // If the array passed in is empty, there are no more results so the content inset of the collection view is reset.
            {
                self.collectionView?.contentInset.bottom = self.tabBarController?.tabBar.frame.height ?? 0
            } else {
                self.collectionViewController.hasNextPage = true
            }
            self.collectionView?.reloadData()
            self.setNeedsFocusUpdate()
        }
    }
    #if os(tvOS)
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if !UserDefaults.standard.bool(forKey: "informedForViewChanges") {
            guard let informationNib = Bundle.main.loadNibNamed("SidePanelIntroduction", owner: self, options: nil)?.first as? SidePanelIntroduction, let textView = informationNib.subviews[0].subviews[2].subviews[0].subviews[0].subviews.first as? UITextView
                else{
                    return
                }
            (tabBarController as? TVTabBarController)?.environmentsToFocus = informationNib.subviews
            textView.isUserInteractionEnabled = true
            view.addSubview(informationNib)
            self.setNeedsFocusUpdate()
            if self.sidePanelConstraint?.constant == 0 {
                UIView.animate(withDuration: 0.4) {
                    self.sidePanelConstraint?.constant += self.view.frame.size.width/4
                    self.view.layoutIfNeeded()
                }
            }
        }
    }
    #endif
}
