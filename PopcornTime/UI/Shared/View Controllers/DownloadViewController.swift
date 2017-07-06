

import Foundation
import PopcornTorrent
import PopcornKit
import MediaPlayer.MPMediaItem

#if os(iOS)
    typealias UIDownloadViewController = UITableViewController
#elseif os(tvOS)
    typealias UIDownloadViewController = UIViewController
#endif

class DownloadViewController: UIDownloadViewController, PTTorrentDownloadManagerListener {
    
    @IBOutlet var segmentedControl: UISegmentedControl!
    
    #if os(tvOS)
        @IBOutlet var tableView: UITableView?
    #endif
    
    var completedEpisodes: [PTTorrentDownload] {
        return filter(downloads: PTTorrentDownloadManager.shared().completedDownloads, through: .episode)
    }
    
    var completedMovies: [PTTorrentDownload] {
        return filter(downloads: PTTorrentDownloadManager.shared().completedDownloads, through: .movie)
    }
    
    var downloadingEpisodes: [PTTorrentDownload] {
        return filter(downloads: PTTorrentDownloadManager.shared().activeDownloads, through: .episode)
    }
    
    var downloadingMovies: [PTTorrentDownload] {
        return filter(downloads: PTTorrentDownloadManager.shared().activeDownloads, through: .movie)
    }
    
    private func filter(downloads: [PTTorrentDownload], through predicate: MPMediaType) -> [PTTorrentDownload] {
        return downloads.filter { download in
            guard let rawValue = download.mediaMetadata[MPMediaItemPropertyMediaType] as? NSNumber else { return false }
            let type = MPMediaType(rawValue: rawValue.uintValue)
            return type == predicate
        }.sorted { (first, second) in
            guard
                let firstTitle = first.mediaMetadata[MPMediaItemPropertyTitle] as? String,
                let secondTitle = second.mediaMetadata[MPMediaItemPropertyTitle] as? String
                else {
                    return false
            }
            return firstTitle > secondTitle
        }
    }
    
    func activeDataSource(in section: Int) -> [AnyHashable] {
        switch (segmentedControl.selectedSegmentIndex, section) {
        case (0, 0):
            return downloadingMovies
        case (0, 1):
            return downloadingEpisodes
        case (1, 0):
            return completedMovies
        case (1, 1):
            var shows = [Show]()
            completedEpisodes.forEach {
                guard let show = Episode($0.mediaMetadata)?.show, !shows.contains(show) else { return }
                shows.append(show)
            }
            return shows
        default:
            fatalError()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        reloadData()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        sharedSetup()
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        sharedSetup()
    }
    
    #if os(iOS)
    
    override init(style: UITableViewStyle) {
        super.init(style: style)
        sharedSetup()
    }
    
    #endif
    
    func sharedSetup() {
        PTTorrentDownloadManager.shared().add(self)
    }
    
    deinit {
        PTTorrentDownloadManager.shared().remove(self)
    }
    
    @IBAction func changeSegment(_ sender: UISegmentedControl) {
        reloadData()
    }
    
    func downloadStatusDidChange(_ downloadStatus: PTTorrentDownloadStatus, for download: PTTorrentDownload) {
        reloadData()
    }
    
    func downloadDidFail(_ download: PTTorrentDownload, withError error: Error) {
        reloadData()
        AppDelegate.shared.download(download, failedWith: error)
    }
}
