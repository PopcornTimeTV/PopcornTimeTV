

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
        searchBar.scopeButtonTitles = ["Movies", "Shows", "People"]
        searchBar.showsScopeBar = true
        searchBar.delegate = self
        searchBar.keyboardAppearance = .dark
        searchBar.searchBarStyle = .minimal
        searchBar.sizeToFit()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        searchContainerViewController = searchContainerViewController ?? {
            let container = UISearchContainerViewController(searchController: searchController)
            
            addChildViewController(container)
            view.addSubview(container.view)
            container.didMove(toParentViewController: self)
            
            return container
        }()
    }
}
