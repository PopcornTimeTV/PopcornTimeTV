

import Foundation

extension SearchViewController {
    
    override func viewDidLoad() {
        // Make sure we set this before calling super as it is not being loaded from storyboard.
        collectionViewController = storyboard?.instantiateViewController(withIdentifier: "CollectionViewController") as! CollectionViewController
        
        super.viewDidLoad()
        
        collectionViewController.delegate = self
        collectionViewController.paginated = false

        searchController = UISearchController(searchResultsController: collectionViewController)
        searchController.hidesNavigationBarDuringPresentation = false
        if #available(tvOS 9.1, *) {
            searchController.obscuresBackgroundDuringPresentation = false
        }
        
        searchBar = searchController.searchBar
        searchBar.scopeButtonTitles = ["Movies".localized, "Shows".localized, "People".localized]
        searchBar.showsScopeBar = true
        searchBar.delegate = self
        searchBar.keyboardAppearance = .dark
        searchBar.searchBarStyle = .minimal
        searchBar.sizeToFit()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        /*work-around to get the scopeBar to appear - NOTE: I need to find why it is happening and the
         parent subview of the scopebar has an alpha of 0!!!!*/
        if #available(tvOS 11.3, *){}else {
            for sub in self.view.subviews{
                for subv in sub.subviews{
                    for subvi in subv.subviews{
                        subvi.alpha = 1.0
                    }
                }
            }
        }
        super.viewDidAppear(animated)
        
        searchContainerViewController = searchContainerViewController ?? {
            let container = UISearchContainerViewController(searchController: searchController)
            
            addChild(container)
            view.addSubview(container.view)
            container.didMove(toParent: self)
            
            return container
        }()
    }
}
