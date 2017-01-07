

import UIKit
import AlamofireImage
import PopcornKit
import PopcornTorrent
import FloatRatingView

class ShowDetailViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UIViewControllerTransitioningDelegate, UIPopoverPresentationControllerDelegate {
    
    @IBOutlet var segmentedControl: UISegmentedControl!
    @IBOutlet var tableHeaderView: UIView!
    @IBOutlet var tableView: UITableView!
    
    @IBOutlet var backgroundImageView: UIImageView!
    
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var infoLabel: UILabel!
    
    @IBOutlet var ratingView: FloatRatingView!
    @IBOutlet var summaryView: ExpandableTextView!
    @IBOutlet var blurView: UIVisualEffectView!
    @IBOutlet var gradientViews: [GradientView]!
    
    @IBOutlet var castButton: CastIconBarButtonItem!
    
    let interactor = EpisodeDetailPercentDrivenInteractiveTransition()

    /// Set this variable to false if you need to animate the layout of the splitView
    var shouldLayoutSplit = true
    
    var currentType: Trakt.MediaType = .shows
    var currentItem: Show!
    var episodesLeftInShow = [Episode]()
    
    
    /* Because UISplitViewControllers are not meant to be pushed to the navigation heirarchy, we are tricking it into thinking it is a root view controller when in fact it is just a childViewController of ShowContainerViewController. Because of the fact that child view controllers should not be aware of their container view controllers, this variable had to be created to access the navigationController and the tabBarController of the viewController. In order to further trick the view controller, navigationController, navigationItem and tabBarController properties have been overridden to point to their corrisponding parent properties.
     */
    var parentTabBarController: UITabBarController?
    var parentNavigationController: UINavigationController?
    var parentNavigationItem: UINavigationItem?
    
    override var navigationItem: UINavigationItem {
        return parentNavigationItem ?? super.navigationItem
    }
    
    override var navigationController: UINavigationController? {
        return parentNavigationController
    }
    
    override var tabBarController: UITabBarController? {
        return parentTabBarController
    }
    
    var currentSeason: Int! {
        didSet {
            self.tableView.reloadData()
        }
    }
    var currentSeasonArray = [Episode]()
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.isBackgroundHidden = true
        navigationController?.navigationBar.frame.size.width = splitViewController?.primaryColumnWidth ?? view.bounds.width
        
        WatchedlistManager<Episode>.episode.getProgress()
        WatchedlistManager<Episode>.episode.getWatched() { _ in
            self.tableView.reloadData()
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(updateCastStatus), name: .gckCastStateDidChange, object: nil)
        
        if transitionCoordinator?.viewController(forKey: .from) is LoadingViewController {
            transitionCoordinator?.animate(alongsideTransition: { (context) in
                guard let tabBarFrame = self.tabBarController?.tabBar.frame else { return }
                
                let tabBarOffsetY = -tabBarFrame.size.height
                self.tabBarController?.tabBar.frame = tabBarFrame.offsetBy(dx: 0, dy: tabBarOffsetY)
                
                self.gradientViews.forEach({ $0.alpha = 1.0 })
                self.segmentedControl.alpha = 1.0
                
                self.splitViewController?.minimumPrimaryColumnWidth = UIScreen.main.bounds.width/1.7
                self.splitViewController?.maximumPrimaryColumnWidth = UIScreen.main.bounds.width/1.7
                
                self.view.layoutIfNeeded()
            }, completion: { _ in
                self.shouldLayoutSplit = true
                self.layoutSplitViewControllerIfNeeded()
            })
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.navigationBar.isBackgroundHidden = false
        navigationController?.navigationBar.frame.size.width = UIScreen.main.bounds.width
        shouldLayoutSplit = false
        NotificationCenter.default.removeObserver(self)
        
        if transitionCoordinator?.viewController(forKey: .to) is LoadingViewController {
            transitionCoordinator?.animate(alongsideTransition: { (context) in
                guard let tabBarFrame = self.tabBarController?.tabBar.frame, let navigationBarFrame = self.navigationController?.navigationBar.frame else { return }
                
                let tabBarOffsetY = tabBarFrame.size.height
                let navigationOffsetY = -(navigationBarFrame.size.height + self.statusBarHeight)
                
                self.tabBarController?.tabBar.frame = tabBarFrame.offsetBy(dx: 0, dy: tabBarOffsetY)
                self.navigationController?.navigationBar.frame = navigationBarFrame.offsetBy(dx: 0, dy: navigationOffsetY)
                
                self.gradientViews.forEach({ $0.alpha = 0.0 })
                self.segmentedControl.alpha = 0.0
                
                self.splitViewController?.minimumPrimaryColumnWidth = UIScreen.main.bounds.width
                self.splitViewController?.maximumPrimaryColumnWidth = UIScreen.main.bounds.width
                
                self.view.layoutIfNeeded()
            }, completion: nil)
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        layoutSplitViewControllerIfNeeded()
        
        tableView.sizeHeaderThatFits(CGSize(width: tableHeaderView.frame.width, height: 115.0 + summaryView.bounds.height))
    }
    
    func layoutSplitViewControllerIfNeeded() {
        guard shouldLayoutSplit else { return }
        
        splitViewController?.minimumPrimaryColumnWidth = UIScreen.main.bounds.width/1.7
        splitViewController?.maximumPrimaryColumnWidth = UIScreen.main.bounds.width/1.7
        
        navigationController?.navigationBar.frame.size.width = splitViewController?.primaryColumnWidth ?? view.bounds.width
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        splitViewController?.delegate = self
        splitViewController?.preferredDisplayMode = .allVisible
        navigationItem.title = currentItem.title
        (castButton.customView as! CastIconButton).addTarget(self, action: #selector(castButtonTapped), for: .touchUpInside)
        
        let inset = tabBarController?.tabBar.frame.height ?? 0.0
        tableView.contentInset.bottom = inset
        tableView.scrollIndicatorInsets.bottom = inset
        tableView.rowHeight = UITableViewAutomaticDimension
        
        titleLabel.text = currentItem.title
        infoLabel.text = currentItem.year
        ratingView.rating = currentItem.rating
        
        let completion: (Show?, NSError?) -> Void = { [weak self] (show, error) in
            guard let `self` = self, let show = show else { return }
            self.currentItem = show
            self.summaryView.text = self.currentItem.summary
            self.infoLabel.text = "\(self.currentItem.year) ● \(self.currentItem.status!.capitalized) ● \(self.currentItem.genres.first!.capitalized)"
            
            self.segmentedControl.removeAllSegments()
            self.segmentedControl.insertSegment(withTitle: "ABOUT", at: 0, animated: true)
            for index in self.currentItem.seasonNumbers {
                self.segmentedControl.insertSegment(withTitle: "SEASON \(index)", at: index, animated: true)
            }
            self.segmentedControl.selectedSegmentIndex = 0
            self.segmentedControl.setTitleTextAttributes([NSFontAttributeName: UIFont.systemFont(ofSize: 11, weight: UIFontWeightMedium)],for: .normal)
            self.segmentedControlDidChangeSegment(self.segmentedControl)
            
            self.tableView.reloadData()
        }
        
        if currentType == .animes {
            PopcornKit.getAnimeInfo(currentItem.id, completion: completion)
        } else {
            PopcornKit.getShowInfo(currentItem.id, completion: completion)
        }
    }
    
    func loadMovieTorrent(_ media: Episode, animated: Bool, onChromecast: Bool) {
        // TODO: Implement
    }
    
    func dismiss() {
        splitViewController?.dismissTopWindow(animated: true)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if let coverImageAsString = currentItem.mediumCoverImage,
            let backgroundImageAsString = currentItem.largeBackgroundImage {
            backgroundImageView.af_setImage(withURLRequest: URLRequest(url: URL(string: splitViewController?.traitCollection.horizontalSizeClass == .compact ? coverImageAsString : backgroundImageAsString)!), placeholderImage: UIImage(named: "Episode Placeholder"), imageTransition: .crossDissolve(animationLength))
        }
    }
    
    // MARK: - UITableViewDataSource
    
    func numberOfSections(in tableView: UITableView) -> Int {
        if segmentedControl.selectedSegmentIndex == 0 {
            tableView.tableHeaderView = tableHeaderView
            return 0
        }
        tableView.tableHeaderView = nil
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if !currentItem.episodes.isEmpty {
            currentSeasonArray.removeAll()
            currentSeasonArray = groupedEpisodes(bySeason: currentSeason)
            return currentSeasonArray.count
        }
        return 0
    }
    
    func groupedEpisodes(bySeason season: Int) -> [Episode] {
        return currentItem.episodes.filter({$0.season == season}).sorted(by: {$0.0.episode < $0.1.episode})
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! ShowDetailTableViewCell
        cell.titleLabel.text = currentSeasonArray[indexPath.row].title
        cell.seasonLabel.text = "E" + String(currentSeasonArray[indexPath.row].episode)
        cell.id = currentSeasonArray[indexPath.row].id
        return cell
    }
    
    
    // MARK: - SegmentedControl
    
    @IBAction func segmentedControlDidChangeSegment(_ segmentedControl: UISegmentedControl) {
        currentSeason = segmentedControl.selectedSegmentIndex == 0 ? Int.max: currentItem.seasonNumbers[segmentedControl.selectedSegmentIndex - 1]
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showCasts", let vc = (segue.destination as? UINavigationController)?.viewControllers.first as? StreamToDevicesTableViewController {
            segue.destination.popoverPresentationController?.delegate = self
            vc.onlyShowCastDevices = true
        } else if segue.identifier == "showDetail",
            let cell = sender as? ShowDetailTableViewCell,
            let indexPath = tableView.indexPath(for: cell),
            let vc = segue.destination as? EpisodeDetailViewController {
            vc.currentItem = currentSeasonArray[indexPath.row]
            var episodesLeftInShow = [Episode]()
            
            for season in currentItem.seasonNumbers {
                episodesLeftInShow += groupedEpisodes(bySeason: season)
            }
            
            let index = episodesLeftInShow.index(of: vc.currentItem!)!
            episodesLeftInShow.removeFirst(index + 1)
            
            self.episodesLeftInShow = episodesLeftInShow
            vc.delegate = self
            vc.transitioningDelegate = self
            vc.modalPresentationStyle = .custom
            vc.interactor = interactor
        }
    }
    
    func castButtonTapped() {
        performSegue(withIdentifier: "showCasts", sender: castButton)
    }
    
    func updateCastStatus() {
        (castButton.customView as! CastIconButton).status = GCKCastContext.sharedInstance().castState
    }
    
    func presentationController(_ controller: UIPresentationController, viewControllerForAdaptivePresentationStyle style: UIModalPresentationStyle) -> UIViewController? {
        (controller.presentedViewController as! UINavigationController).topViewController?.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(cancelButtonPressed))
        return controller.presentedViewController
        
    }
    
    func cancelButtonPressed() {
        self.dismiss(animated: true, completion: nil)
    }
    
    
    // MARK: - Presentation
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        if presented is LoadingViewController {
            return LoadingViewAnimatedTransitioning(isPresenting: true)
        } else if presented is EpisodeDetailViewController {
            return EpisodeDetailAnimatedTransitioning(isPresenting: true)
        }
        return nil
        
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        if dismissed is LoadingViewController {
            return LoadingViewAnimatedTransitioning(isPresenting: false)
        } else if dismissed is EpisodeDetailViewController {
            return EpisodeDetailAnimatedTransitioning(isPresenting: false)
        }
        return nil
    }
    
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        return presented is EpisodeDetailViewController ? EpisodeDetailPresentationController(presentedViewController: presented, presenting: presenting) : nil
    }
    
    func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        if animator is EpisodeDetailAnimatedTransitioning && interactor.hasStarted && splitViewController!.isCollapsed  {
            return interactor
        }
        return nil
    }
}

extension ShowDetailViewController: UISplitViewControllerDelegate {
    
    func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController: UIViewController, onto primaryViewController: UIViewController) -> Bool {
        guard let secondaryViewController = secondaryViewController as? EpisodeDetailViewController, secondaryViewController.currentItem != nil else { return true }
        primaryViewController.present(secondaryViewController, animated: true, completion: nil)
        secondaryViewController.view.setNeedsLayout()
        secondaryViewController.view.layoutIfNeeded()
        secondaryViewController.scrollView.setNeedsLayout()
        secondaryViewController.scrollView.layoutIfNeeded()
        return true
    }
    
    func splitViewController(_ splitViewController: UISplitViewController, separateSecondaryFrom primaryViewController: UIViewController) -> UIViewController? {
        guard let vc = primaryViewController.presentedViewController as? EpisodeDetailViewController else { return nil }
        primaryViewController.dismiss(animated: false, completion: nil)
        return vc
    }
}
