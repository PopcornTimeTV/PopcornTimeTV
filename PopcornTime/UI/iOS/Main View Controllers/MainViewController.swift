

import UIKit
import PopcornKit

class MainViewController: UIViewController, CollectionViewControllerDelegate, GenresDelegate, UIPopoverPresentationControllerDelegate {
    
    func load(page: Int) {}
    func populateGenres(_ array: inout [String]) {}
    func didSelectGenre(at index: Int) {}
    func didSelectFilter(at index: Int) {}
    func collectionView(isEmptyForUnknownReason collectionView: UICollectionView) {}
    
    let cache = NSCache<AnyObject, UINavigationController>()
    
    var collectionViewController: CollectionViewController!
    
    var collectionView: UICollectionView? {
        get {
            return collectionViewController.collectionView
        } set(newObject) {
            collectionViewController.collectionView = newObject
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionViewController.paginated = true
        load(page: 1)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.tintColor = .app
        self.collectionView?.reloadData()
    }
    
    @IBAction func showGenres(_ sender: UIBarButtonItem) {
        let vc = cache.object(forKey: self) ?? {
            let vc = storyboard?.instantiateViewController(withIdentifier: "GenresNavigationController") as! UINavigationController
            cache.setObject(vc, forKey: self)
            (vc.viewControllers.first as! GenresTableViewController).delegate = self
            vc.modalPresentationStyle = .popover
            return vc
        }()
        vc.popoverPresentationController?.backgroundColor = UIColor(red: 28.0/255.0, green: 28.0/255.0, blue: 28.0/255.0, alpha: 1.0)
        vc.popoverPresentationController?.barButtonItem = sender
        present(vc, animated: true, completion: nil)
    }
    
    func didRefresh(collectionView: UICollectionView) {
        collectionViewController.dataSource.removeAll()
        collectionView.reloadData()
        load(page: 1)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "embed", let vc = segue.destination as? CollectionViewController {
            collectionViewController = vc
            collectionViewController.isRefreshable = true
            collectionViewController.delegate = self
        }
    }
}
