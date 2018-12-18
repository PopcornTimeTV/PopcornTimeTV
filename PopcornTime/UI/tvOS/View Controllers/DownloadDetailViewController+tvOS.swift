

import Foundation
import PopcornKit
import PopcornTorrent
import MediaPlayer.MPMediaItem

extension DownloadDetailViewController: UITableViewDataSource, UITableViewDelegate {
    
    private struct AssociatedKeys {
        static var environmentsToFocusKey = "DownloadDetailViewController.environmentsToFocusKey"
        static var guideKey = "DownloadDetailViewController.guideKey"
    }
    
    var environmentsToFocus: [UIFocusEnvironment] {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.environmentsToFocusKey) as? [UIFocusEnvironment] ?? []
        } set {
            objc_setAssociatedObject(self, &AssociatedKeys.environmentsToFocusKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    override var preferredFocusEnvironments: [UIFocusEnvironment] {
        return environmentsToFocus.isEmpty ? super.preferredFocusEnvironments : environmentsToFocus
    }
    
    var guide: UIFocusGuide {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.guideKey) as! UIFocusGuide
        } set {
            objc_setAssociatedObject(self, &AssociatedKeys.guideKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let image = show.largeBackgroundImage, let url = URL(string: image) {
           backgroundImageView.af_setImage(withURL: url, placeholderImage: UIImage(named: "Episode Placeholder"))
        }
        
        titleLabel.text = show.title
        tableView.remembersLastFocusedIndexPath = true
        
        guide = UIFocusGuide()
        
        view.addLayoutGuide(guide)
        
        guide.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        guide.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        guide.leadingAnchor.constraint(equalTo: tableView.trailingAnchor).isActive = true
        guide.trailingAnchor.constraint(equalTo: playButton.leadingAnchor).isActive = true
    }
    
    @IBAction func playDownload(_ sender: TVButton) {
        let indexPath = tableView.focusedCellIndexPath!
        let download  = dataSource(for: seasons[indexPath.section])[indexPath.row]
        
        AppDelegate.shared.play(Episode(download.mediaMetadata)!, torrent: Torrent()) // No torrent metadata necessary, media is loaded from disk.
    }
    
    @IBAction func deleteDownload(_ sender: TVButton) {
        let indexPath = tableView.focusedCellIndexPath!
        let download  = dataSource(for: seasons[indexPath.section])[indexPath.row]
        
        let alertController = UIAlertController(title: "Delete Download".localized, message: "Are you sure you want to delete the download?".localized, preferredStyle: .alert)
        
        alertController.addAction(UIAlertAction(title: "Cancel".localized, style: .cancel, handler: nil))
        
        alertController.addAction(UIAlertAction(title: "Delete".localized, style: .destructive) { [unowned self, unowned download] _ in
            PTTorrentDownloadManager.shared().delete(download)
            self.tableView.reloadData()
            
            var isEmpty = true
            
            for section in 0..<self.tableView.numberOfSections {
                if self.tableView.numberOfRows(inSection: section) > 0 {
                    isEmpty = false
                    break
                }
            }
            
            if isEmpty {
                self.navigationController?.pop(animated: true)
            }
        })
        
        present(alertController, animated: true)
    }
    
    
    // MARK: - UITableViewDataSource
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return seasons.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource(for: seasons[section]).count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell") as! DownloadDetailTableViewCell
        let download = dataSource(for: seasons[indexPath.section])[indexPath.row]
        
        let episodeNumber = NumberFormatter.localizedString(from: NSNumber(value: download.mediaMetadata[MPMediaItemPropertyEpisode] as? Int ?? 0), number: .none)
        let episodeTitle = download.mediaMetadata[MPMediaItemPropertyTitle] as? String ?? ""
        
        cell.leftDetailLabel?.text = episodeNumber
        cell.textLabel?.text = episodeTitle
        cell.detailTextLabel?.text = download.fileSize.stringValue
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let localizedSeason = NumberFormatter.localizedString(from: NSNumber(value: seasons[section]), number: .none)
        return "Season".localized + " \(localizedSeason)"
    }
    
    // MARK: - UITableViewDelegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        environmentsToFocus = [playButton]
        setNeedsFocusUpdate()
        updateFocusIfNeeded()
        environmentsToFocus.removeAll()
    }
    
    func tableView(_ tableView: UITableView, didUpdateFocusIn context: UITableViewFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        
        tableView.visibleCells.compactMap({$0 as? DownloadDetailTableViewCell}).forEach {
            $0.invalidateAppearance()
        }
        
        guard let nextIndexPath = context.nextFocusedIndexPath else { return }
        
        workItem?.cancel()
        
        workItem = DispatchWorkItem { [weak self] in
            guard
                let `self` = self,
                let download = self.dataSource(for: self.seasons[nextIndexPath.section])[nextIndexPath.row] as PTTorrentDownload?,
                let episode = Episode(download.mediaMetadata),
                let image = episode.mediumBackgroundImage,
                let url = URL(string: image)
            else {
                return
            }
            
            self.episodeImageView.af_setImage(withURL: url, placeholderImage: UIImage(named: "Episode Placeholder"))
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: workItem)
    }
    
    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        if let next = context.nextFocusedView {
            if next.isDescendant(of: tableView) {
                guide.preferredFocusEnvironments = [playButton]
            } else if next == playButton {
                guide.preferredFocusEnvironments = [tableView]
            }
        }
    }
}
