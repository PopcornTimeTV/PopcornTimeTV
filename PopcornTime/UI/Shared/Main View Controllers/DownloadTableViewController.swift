

import Foundation
import PopcornTorrent
import PopcornKit
import MediaPlayer.MPMediaItem

class DownloadTableViewController: UITableViewController, PTTorrentDownloadManagerListener, DownloadTableViewCellDelegate {
    
    @IBOutlet var segmentedControl: UISegmentedControl!
    
    var completedDownloads: [PTTorrentDownload] {
        return PTTorrentDownloadManager.shared().completedDownloads
    }
    var activeDownloads: [PTTorrentDownload] {
        return PTTorrentDownloadManager.shared().activeDownloads
    }
    
    override init(style: UITableViewStyle) {
        super.init(style: style)
        sharedSetup()
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        sharedSetup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        sharedSetup()
    }
    
    func sharedSetup() {
        PTTorrentDownloadManager.shared().add(self)
    }
    
    deinit {
        PTTorrentDownloadManager.shared().remove(self)
    }
    
    @IBAction func changeSegment(_ sender: UISegmentedControl) {
        tableView.reloadData()
        editButtonItem.isEnabled = sender.selectedSegmentIndex == 0 ? false : true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        editButtonItem.isEnabled = false
        navigationItem.rightBarButtonItem = editButtonItem
        tableView.tableFooterView = UIView()
    }
    
    func downloadStatusDidChange(_ downloadStatus: PTTorrentDownloadStatus, for download: PTTorrentDownload) {
        tableView.reloadData()
    }
    
    func torrentStatusDidChange(_ torrentStatus: PTTorrentStatus, for download: PTTorrentDownload) {
        tableView.reloadData()
    }
    
    func downloadDidFail(_ download: PTTorrentDownload, withError error: Error) {
        tableView.reloadData()
        AppDelegate.shared.download(download, failedWith: error)
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        tableView.backgroundView = nil
        let dataSource = segmentedControl.selectedSegmentIndex == 0 ? activeDownloads : completedDownloads
        if dataSource.isEmpty {
            let background: ErrorBackgroundView? = .fromNib()
            background?.setUpView(title: "Downloads Empty".localized, description: "Movies and episodes you download will show up here.".localized)
            tableView.backgroundView = background
        }
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let value = activeDownloads.count
        navigationController?.tabBarItem.badgeValue = value == 0 ? nil : NumberFormatter.localizedString(from: NSNumber(value: value), number: .none)
        return (segmentedControl.selectedSegmentIndex == 0 ? activeDownloads : completedDownloads).count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell") as! DownloadTableViewCell
        cell.delegate = self
        let download: PTTorrentDownload
        
        if segmentedControl.selectedSegmentIndex == 0 {
            download = activeDownloads[indexPath.row]
            
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
            download = completedDownloads[indexPath.row]
            cell.detailTextLabel?.text = download.fileSize.stringValue
        }
        
        cell.textLabel?.text = download.mediaMetadata[MPMediaItemPropertyTitle] as? String
        cell.downloadButton.progress = download.torrentStatus.totalProgress
        cell.downloadButton.downloadState = DownloadButton.State(download.downloadStatus)
        
        if let image = download.mediaMetadata[MPMediaItemPropertyArtwork] as? String, let url = URL(string: image) {
            cell.imageView?.af_setImage(withURL: url)
        } else {
            cell.imageView?.image = UIImage(named: "Episode Placeholder")
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete else { return }
        
        let download = completedDownloads[indexPath.row] // Deleting downloads is not available for active downloads.
        PTTorrentDownloadManager.shared().delete(download)
        tableView.deleteRows(at: [indexPath], with: .fade)
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return segmentedControl.selectedSegmentIndex == 1
    }
    
    func cell(_ cell: DownloadTableViewCell, accessoryButtonPressed button: DownloadButton) {
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        
        let download = (segmentedControl.selectedSegmentIndex == 0 ? activeDownloads : completedDownloads)[indexPath.row]
        
        AppDelegate.shared.downloadButton(button, wasPressedWith: download) { [unowned self] in
            self.tableView.reloadData()
        }
    }
    
    func cell(_ cell: DownloadTableViewCell, longPressDetected gesture: UILongPressGestureRecognizer) {
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        
        let download = activeDownloads[indexPath.row] // Long press will only be called when the buttons download is either downloading or paused.
        
        AppDelegate.shared.downloadButton(cell.downloadButton, wantsToStop: download) { [unowned self] in
            self.tableView.reloadData()
        }
    }
}
