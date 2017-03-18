

import UIKit
import PopcornKit

class MainViewController: UIViewController, CollectionViewControllerDelegate {
    
    func load(page: Int) {}
    func collectionView(isEmptyForUnknownReason collectionView: UICollectionView) {}
    func collectionView(_ collectionView: UICollectionView, titleForHeaderInSection section: Int) -> String? { return nil }
    func collectionView(nibForHeaderInCollectionView collectionView: UICollectionView) -> UINib? { return nil }
    
    func minItemSize(forCellIn collectionView: UICollectionView, at indexPath: IndexPath) -> CGSize? { return nil }
    func collectionView(_ collectionView: UICollectionView, insetForSectionAt section: Int) -> UIEdgeInsets? { return nil }
    
    
    var collectionViewController: CollectionViewController!
    
    var collectionView: UICollectionView? {
        get {
            return collectionViewController?.collectionView
        } set(newObject) {
            collectionViewController?.collectionView = newObject
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        #if os(iOS)
            navigationController?.navigationBar.isBackgroundHidden = false
        #endif
        navigationController?.navigationBar.tintColor = .app
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        collectionView?.setNeedsFocusUpdate()
        collectionView?.updateFocusIfNeeded()
        
        collectionView?.reloadData()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionViewController.paginated = true
        load(page: 1)
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
            #if os(iOS)
                collectionViewController.isRefreshable = true
            #endif
        } else if let segue = segue as? AutoPlayStoryboardSegue,
            segue.identifier == "showMovie" || segue.identifier == "showShow",
            let media: Media = sender as? Movie ?? sender as? Show,
            let vc = storyboard?.instantiateViewController(withIdentifier: String(describing: DetailViewController.self)) as? DetailViewController {
            
            #if os(tvOS)

                if let destination = segue.destination as? TVLoadingViewController {
                    destination.loadView() // Initialize the @IBOutlets
                    
                    if let image = media.smallCoverImage, let url = URL(string: image) {
                        destination.backgroundImageView.af_setImage(withURL: url)
                    }
                    
                    destination.titleLabel.text = media.title
                }
            
            #endif
            
            // Exact same storyboard UI is being used for both classes. This will enable subclass-specific functions however, stored instance variables have to be set using `object_setIvar` otherwise there will be weird malloc crashes.
            object_setClass(vc, media is Movie ? MovieDetailViewController.self : ShowDetailViewController.self)
            
            #if os(iOS)
                navigationController?.navigationBar.isBackgroundHidden = true
            #endif
            
            vc.loadMedia(id: media.id) { (media, error) in
                guard let navigationController = segue.destination.navigationController,
                    navigationController.visibleViewController === segue.destination // Make sure we're still loading and the user hasn't dismissed the view.
                    else { return }
                
                
                let transition = CATransition()
                transition.duration = 0.5
                transition.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
                transition.type = kCATransitionFade
                navigationController.view.layer.add(transition, forKey: nil)
                
                defer {
                    DispatchQueue.main.asyncAfter(deadline: .now() + transition.duration) {
                        var viewControllers = navigationController.viewControllers
                        if let index = viewControllers.index(where: {$0 === segue.destination}) {
                            viewControllers.remove(at: index)
                            navigationController.setViewControllers(viewControllers, animated: false)
                        }
                        
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
                } else if let currentItem = media {
                    vc.currentItem = currentItem
                    navigationController.pushViewController(vc, animated: false)
                }
            }
        } else if segue.identifier == "showPerson",
            let vc = segue.destination as? PersonViewController,
            let person: Person = sender as? Crew ?? sender as? Actor {
            vc.currentItem = person
        }
    }
}
