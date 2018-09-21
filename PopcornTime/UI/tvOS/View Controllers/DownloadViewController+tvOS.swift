

import Foundation
import PopcornTorrent
import PopcornKit

extension DownloadViewController: CollectionViewControllerDelegate, DownloadCollectionViewCellDelegate, UITableViewDelegate, UITableViewDataSource {
    
    private struct AssociatedKeys {
        static var collectionViewControllerKey = "DownloadViewController.collectionViewControllerKey"
        static var topFocusGuideKey = "DownloadViewController.topFocusGuideKey"
        static var leftFocusGuideKey = "DownloadViewController.leftFocusGuideKey"
    }
    
    var collectionViewController: CollectionViewController? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.collectionViewControllerKey) as? CollectionViewController
        } set {
            objc_setAssociatedObject(self, &AssociatedKeys.collectionViewControllerKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    
    var collectionView: UICollectionView? {
        return collectionViewController?.collectionView
    }
    
    var topFocusGuide: UIFocusGuide {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.topFocusGuideKey) as! UIFocusGuide
        } set {
            objc_setAssociatedObject(self, &AssociatedKeys.topFocusGuideKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    var leftFocusGuide: UIFocusGuide {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.leftFocusGuideKey) as! UIFocusGuide
        } set {
            objc_setAssociatedObject(self, &AssociatedKeys.leftFocusGuideKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        topFocusGuide = UIFocusGuide()
        leftFocusGuide = UIFocusGuide()
        
        view.addLayoutGuide(topFocusGuide)
        view.addLayoutGuide(leftFocusGuide)
        
        topFocusGuide.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor).isActive = true
        topFocusGuide.bottomAnchor.constraint(equalTo: collectionView!.topAnchor).isActive = true
        topFocusGuide.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        topFocusGuide.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        
        leftFocusGuide.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        leftFocusGuide.leadingAnchor.constraint(equalTo: tableView!.trailingAnchor).isActive = true
        leftFocusGuide.trailingAnchor.constraint(equalTo: collectionView!.leadingAnchor).isActive = true
        leftFocusGuide.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        
        tableView!.contentInset.top = 20
        tableView!.remembersLastFocusedIndexPath = true
        tableView!.selectRow(at: tableView!.indexPathForSelectedRow ?? indexPathForPreferredFocusedView(in: tableView!), animated: true, scrollPosition: .none)
    }
    
    func reloadData() {
        if let row = tableView?.indexPathForSelectedRow?.row {
            collectionViewController?.dataSources = [activeDataSource(in: row)]
        }
        let value = (downloadingEpisodes + downloadingMovies).count
        navigationController?.tabBarItem.badgeValue = value == 0 ? nil : NumberFormatter.localizedString(from: NSNumber(value: value), number: .none)
        collectionView?.reloadData()
        
        let selectedIndex = tableView?.indexPathForSelectedRow
        tableView?.reloadData()
        tableView?.selectRow(at: selectedIndex, animated: false, scrollPosition: .none)
    }
    
    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        if let next = context.nextFocusedView {
            if next.isDescendant(of: segmentedControl) {
                topFocusGuide.preferredFocusEnvironments = [collectionView!]
                leftFocusGuide.preferredFocusEnvironments = [tableView!]
            } else if next.isDescendant(of: tableView!) {
                leftFocusGuide.preferredFocusEnvironments = [collectionView!, segmentedControl]
            } else {
                topFocusGuide.preferredFocusEnvironments = [segmentedControl]
                leftFocusGuide.preferredFocusEnvironments = [tableView!]
            }
        }
    }
    
    // MARK: - PTTorrentDownloadManagerListener
    
    func torrentStatusDidChange(_ torrentStatus: PTTorrentStatus, for download: PTTorrentDownload) {
        let visibleCells = collectionView?.visibleCells ?? []
        
        for cell in visibleCells {
            guard
                let cell = cell as? DownloadCollectionViewCell,
                let indexPath = collectionView?.indexPath(for: cell),
                let section   = tableView?.indexPathForSelectedRow?.row,
                let download  = activeDataSource(in: section)[safe: indexPath.row] as? PTTorrentDownload
                else {
                    continue
            }
            cell.progress = download.torrentStatus.totalProgress
        }
    }
    
    // MARK: - DownloadCollectionViewCellDelegate
    
    func cell(_ cell: DownloadCollectionViewCell, longPressDetected gesture: UILongPressGestureRecognizer) {
        guard let indexPath = collectionView?.indexPath(for: cell) else { return }
        
        let download = activeDataSource(in: tableView!.indexPathForSelectedRow!.row)[indexPath.row] as! PTTorrentDownload
        
        if download.downloadStatus == .finished {
            let alertController = UIAlertController(title: "Delete Download".localized, message: "Are you sure you want to delete the download?".localized, preferredStyle: .alert)
            
            alertController.addAction(UIAlertAction(title: "Cancel".localized, style: .cancel, handler: nil))
            
            alertController.addAction(UIAlertAction(title: "Delete".localized, style: .destructive) { [unowned self] _ in
                PTTorrentDownloadManager.shared().delete(download)
                self.reloadData()
            })
            
            alertController.show(animated: true)
        } else {
            AppDelegate.shared.downloadButton(nil, wantsToStop: download) { [unowned self] in
                self.reloadData()
            }
        }
    }
    
    // MARK: - CollectionViewControllerDelegate
    
    func collectionView(isEmptyForUnknownReason collectionView: UICollectionView) {
        if let background: ErrorBackgroundView = .fromNib() {
            background.setUpView(title: "Downloads Empty".localized, description: "Movies and episodes you download will show up here.".localized)
            collectionView.backgroundView = background
        }
    }
    
    func minItemSize(forCellIn collectionView: UICollectionView, at indexPath: IndexPath) -> CGSize? {
        return CGSize(width: 225, height: 414)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) -> Bool {
        let section = tableView!.indexPathForSelectedRow!.row
        let item = activeDataSource(in: section)[indexPath.row]
        
        if let download = item as? PTTorrentDownload {
            let button = DownloadButton()
            button.downloadState = DownloadButton.ButtonState(download.downloadStatus)
            
            AppDelegate.shared.downloadButton(button, wasPressedWith: download) { [unowned self] in
                self.reloadData()
            }
        } else {
            let show = item as! Show
            
            let vc = storyboard?.instantiateViewController(withIdentifier: String(describing:DownloadDetailViewController.self)) as! DownloadDetailViewController
            vc.show = show
            
            navigationController?.push(vc, animated: true)
        }
        
        return true
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "embed", let vc = segue.destination as? CollectionViewController {
            vc.delegate = self
            collectionViewController = vc
        }
    }
    
    // MARK: - UITableViewDataSource
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let count: Int
        let text: String
        
        if indexPath.row == 0 {
            count = (completedMovies + downloadingMovies).count
            text = "Movies".localized
        } else {
            count = downloadingEpisodes.count + {
                var shows = [Show]()
                completedEpisodes.forEach {
                    guard let show = Episode($0.mediaMetadata)?.show, !shows.contains(show) else { return }
                    shows.append(show)
                }
                return shows.count
            }()
            text = "Shows".localized
        }
        
        cell.detailTextLabel?.text = NumberFormatter.localizedString(from: NSNumber(value: count), number: .decimal)
        cell.textLabel?.text = text
        
        return cell
    }
    
    // MARK: - UITableViewDelegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        reloadData()
    }
    
    func indexPathForPreferredFocusedView(in tableView: UITableView) -> IndexPath? {
        return IndexPath(row: 0, section: 0)
    }
}
