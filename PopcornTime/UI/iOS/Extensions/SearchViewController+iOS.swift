

import Foundation

extension SearchViewController: UIToolbarDelegate {
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.isHairlineHidden = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.navigationBar.isHairlineHidden = false
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionViewController.paginated = false
        
        searchBar.keyboardAppearance = .dark
        collectionView?.contentInset.top = toolbar.frame.height
        
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        segmentedControl.leadingAnchor.constraint(equalTo: toolbar.leadingAnchor, constant: 12.0).isActive = true
        segmentedControl.trailingAnchor.constraint(equalTo: toolbar.trailingAnchor, constant: -12.0).isActive = true
        segmentedControl.centerYAnchor.constraint(equalTo: toolbar.centerYAnchor).isActive = true
    }
    
    @IBAction func segmentedControlDidChangeSegment(_ segmentedControl: UISegmentedControl) {
        searchBar(searchBar, selectedScopeButtonIndexDidChange: segmentedControl.selectedSegmentIndex)
    }
    
    // MARK: - UISearchBar delegate
    
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        searchBar.showsCancelButton = true
        return true
    }
    
    func searchBarShouldEndEditing(_ searchBar: UISearchBar) -> Bool {
        searchBar.showsCancelButton = false
        return true
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    // MARK: - UIToolbar delegate
    
    func position(for bar: UIBarPositioning) -> UIBarPosition {
        return .topAttached
    }
}
