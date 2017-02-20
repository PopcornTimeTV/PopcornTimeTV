

import UIKit
import PopcornKit

class MainViewController: UIViewController, CollectionViewControllerDelegate, GenresDelegate, UIPopoverPresentationControllerDelegate {
    
    func load(page: Int) {}
    func populateGenres(_ array: inout [String]) {}
    func didSelectGenre(at index: Int) {}
    func didSelectFilter(at index: Int) {}
    func collectionView(isEmptyForUnknownReason collectionView: UICollectionView) {}
    func collectionView(_ collectionView: UICollectionView, titleForHeaderInSection section: Int) -> String? { return nil }
    
    let cache = NSCache<AnyObject, UINavigationController>()
    
    var collectionViewController: CollectionViewController!
    
    var collectionView: UICollectionView? {
        get {
            return collectionViewController.collectionView
        } set(newObject) {
            collectionViewController.collectionView = newObject
        }
    }
    
    func collectionView(nibForHeaderInCollectionView collectionView: UICollectionView) -> UINib? { return nil }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionViewController.paginated = true
        load(page: 1)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.tintColor = .app
        navigationController?.navigationBar.isBackgroundHidden = false
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
        collectionViewController.dataSources = [[]]
        collectionView.reloadData()
        load(page: 1)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "embed", let vc = segue.destination as? CollectionViewController {
            collectionViewController = vc
            collectionViewController.delegate = self
            collectionViewController.isRefreshable = true
        } else if let segue = segue as? AutoPlayStoryboardSegue,
            segue.identifier == "showMovie" || segue.identifier == "showShow",
            let media: Media = sender as? Movie ?? sender as? Show,
            let vc = storyboard?.instantiateViewController(withIdentifier: String(describing: DetailViewController.self)) as? DetailViewController {
            
            // Exact same storyboard UI is being used for both classes. This will enable subclass-specific functions however, stored instance variables cannot be created on either subclass because object_setClass does not initialise stored variables.
            object_setClass(vc, media is Movie ? MovieDetailViewController.self : ShowDetailViewController.self)
            navigationController?.navigationBar.isBackgroundHidden = true
            
            vc.loadMedia(id: media.id) { (media, error) in
                guard let navigationController = self.navigationController,
                    navigationController.visibleViewController === segue.destination else { return }
                
                let transition = CATransition()
                transition.duration = 0.5
                transition.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
                transition.type = kCATransitionFade
                navigationController.view.layer.add(transition, forKey: nil)
                
                defer {
                    DispatchQueue.main.asyncAfter(deadline: .now() + transition.duration) {
                        var viewControllers = navigationController.viewControllers
                        let index = viewControllers.count - 2
                        viewControllers.remove(at: index)
                        navigationController.setViewControllers(viewControllers, animated: false)
                        
                        if let media = media, segue.shouldAutoPlay {
                           vc.chooseQuality(nil, media: media)
                        }
                    }
                }
                
                if let error = error {
                    let vc = UIViewController()
                    let view: ErrorBackgroundView? = .fromNib()
                    
                    view?.setUpView(error: error)
                    vc.view = view
                    
                    navigationController.pushViewController(vc, animated: false)
                } else {
                    vc.currentItem = media
                    
                    navigationController.pushViewController(vc, animated: false)
                }
            }
        } else if segue.identifier == "showPerson",
            let vc = segue.destination as? PersonDetailCollectionViewController,
            let person = sender as? Person {
            vc.currentItem = person
        }
    }
}
