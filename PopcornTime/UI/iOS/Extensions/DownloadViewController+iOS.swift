

import Foundation
import PopcornTorrent
import MediaPlayer.MPMediaItem
import PopcornKit

extension DownloadViewController: DownloadDetailTableViewCellDelegate {
    
    func reloadData() {
        tableView?.reloadData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.rightBarButtonItem = editButtonItem
        tableView.tableFooterView = UIView()
        tableView.register(UINib(nibName: "DownloadTableViewHeader", bundle: nil), forHeaderFooterViewReuseIdentifier: "header")
    }
    
    func torrentStatusDidChange(_ torrentStatus: PTTorrentStatus, for download: PTTorrentDownload) {
        reloadData()
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        tableView.backgroundView = nil
        let dataSource = activeDataSource(in: 0) + activeDataSource(in: 1)
        if dataSource.isEmpty {
            let background: ErrorBackgroundView? = .fromNib()
            background?.setUpView(title: "Downloads Empty".localized, description: "Movies and episodes you download will show up here.".localized)
            tableView.backgroundView = background
        }
        return 2
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let value = (downloadingEpisodes + downloadingMovies).count
        navigationController?.tabBarItem.badgeValue = value == 0 ? nil : NumberFormatter.localizedString(from: NSNumber(value: value), number: .none)
        
        return activeDataSource(in: section).count
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: "header")
        let label = header?.viewWithTag(1) as? UILabel
        let index = segmentedControl.selectedSegmentIndex
        
        label?.text = (section == 0 ? "Movies" : index == 0 ? "Episodes" : "Shows").localized
        
        return header
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return activeDataSource(in: section).count == 0 ? 0 : 40
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete && segmentedControl.selectedSegmentIndex == 1 else { return }
        
        let downloads: [PTTorrentDownload]
        
        if indexPath.section == 0 {
            downloads = [completedMovies[indexPath.row]]
        } else {
            downloads = completedEpisodes.filter {
                guard
                    let lhs = Episode($0.mediaMetadata)?.show,
                    let rhs = activeDataSource(in: indexPath.section)[indexPath.row] as? Show
                    else { return false }
                return lhs == rhs
            }
        }
        
        downloads.forEach({PTTorrentDownloadManager.shared().delete($0)})
        
        tableView.deleteRows(at: [indexPath], with: .fade)
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return segmentedControl.selectedSegmentIndex == 1
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: DownloadTableViewCell
        let image: String?
        
        if indexPath.section == 1 && segmentedControl.selectedSegmentIndex == 1 // Sort episodes by show instead.
        {
            let show = activeDataSource(in: indexPath.section)[indexPath.row] as! Show
            cell = tableView.dequeueReusableCell(withIdentifier: "downloadCell") as! DownloadTableViewCell
            image = show.smallBackgroundImage
            cell.textLabel?.text = show.title
            let count = completedEpisodes.filter {
                return Episode($0.mediaMetadata)?.show == show
                }.count
            let singular = count == 1
            cell.detailTextLabel?.text = "\(NumberFormatter.localizedString(from: NSNumber(value: count), number: .none)) \(singular ? "Episode".localized : "Episodes".localized)"
        } else {
            let download = activeDataSource(in: indexPath.section)[indexPath.row] as! PTTorrentDownload
            cell = {
                let cell = tableView.dequeueReusableCell(withIdentifier: "downloadDetailCell") as! DownloadDetailTableViewCell
                cell.delegate = self
                cell.downloadButton.progress = download.torrentStatus.totalProgress
                cell.downloadButton.downloadState = DownloadButton.ButtonState(download.downloadStatus)
                cell.downloadButton.invalidateAppearance()
                return cell
            }()
            image = download.mediaMetadata[MPMediaItemPropertyBackgroundArtwork] as? String
            
            cell.textLabel?.text = download.mediaMetadata[MPMediaItemPropertyTitle] as? String
            
            if segmentedControl.selectedSegmentIndex == 0 {
                let speed: String
                let downloadSpeed = TimeInterval(download.torrentStatus.downloadSpeed)
                let sizeLeftToDownload = TimeInterval(download.fileSize.longLongValue - download.totalDownloaded.longLongValue)
                
                if downloadSpeed > 0 {
                    let formatter = DateComponentsFormatter()
                    formatter.unitsStyle = .full
                    formatter.includesTimeRemainingPhrase = true
                    formatter.includesApproximationPhrase = true
                    formatter.allowedUnits = [.hour, .minute]
                    
                    let remainingTime = sizeLeftToDownload/downloadSpeed
                    
                    if let formattedTime = formatter.string(from: remainingTime) {
                        speed = " • " + formattedTime
                    } else {
                        speed = ""
                    }
                } else {
                    speed = ""
                }
                
                cell.detailTextLabel?.text = download.downloadStatus == .paused ?  "Paused".localized : ByteCountFormatter.string(fromByteCount: Int64(download.torrentStatus.downloadSpeed), countStyle: .binary) + "/s" + speed
            } else {
                cell.detailTextLabel?.text = download.fileSize.stringValue
            }
        }
        
        if let image = image, let url = URL(string: image) {
            cell.imageView?.af_setImage(withURL: url)
        } else {
            cell.imageView?.image = UIImage(named: "Episode Placeholder")
        }
        
        return cell
    }
    
    func cell(_ cell: DownloadDetailTableViewCell, accessoryButtonPressed button: DownloadButton) {
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        
        let download = activeDataSource(in: indexPath.section)[indexPath.row] as! PTTorrentDownload
        
        AppDelegate.shared.downloadButton(button, wasPressedWith: download) { [unowned self] in
            self.tableView.reloadData()
        }
    }
    
    func cell(_ cell: DownloadDetailTableViewCell, longPressDetected gesture: UILongPressGestureRecognizer) {
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        
        let download = activeDataSource(in: indexPath.section)[indexPath.row] as! PTTorrentDownload
        
        AppDelegate.shared.downloadButton(cell.downloadButton, wantsToStop: download) { [unowned self] in
            self.tableView.reloadData()
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? DownloadDetailViewController,
            segue.identifier == "showDetail",
            let cell = sender as? UITableViewCell,
            let indexPath = tableView.indexPath(for: cell) {
            destination.show = activeDataSource(in: indexPath.section)[indexPath.row] as! Show
        }
    }
}
