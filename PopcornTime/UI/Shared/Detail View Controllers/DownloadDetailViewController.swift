

import Foundation
import PopcornTorrent
import PopcornKit
import MediaPlayer.MPMediaItem

#if os(tvOS)
    typealias UIDownloadDetailViewController = UIViewController
#elseif os(iOS)
    typealias UIDownloadDetailViewController = UITableViewController
#endif

class DownloadDetailViewController: UIDownloadDetailViewController {
    
    #if os(tvOS)
    
        @IBOutlet var titleLabel: UILabel!
        @IBOutlet var tableView: UITableView!
    
        @IBOutlet var backgroundImageView: UIImageView!
        @IBOutlet var blurView: UIVisualEffectView!
    
        @IBOutlet var episodeImageView: UIImageView!
        @IBOutlet var playButton: TVButton!
        @IBOutlet var deleteButton: TVButton!
    
    #endif
    
    var show: Show!
    var workItem: DispatchWorkItem!
    
    var episodes: [PTTorrentDownload] {
        return PTTorrentDownloadManager.shared().completedDownloads.filter {
            guard let show = Episode($0.mediaMetadata)?.show else { return false }
            return show == self.show
        }
    }
    
    var seasons: [Int] {
        var seasons = [Int]()
        episodes.forEach {
            guard let season = $0.mediaMetadata[MPMediaItemPropertySeason] as? Int, !seasons.contains(season) else { return }
            seasons.append(season)
        }
        return seasons.sorted(by: <)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView?.reloadData()
    }
    
    func dataSource(for season: Int) -> [PTTorrentDownload] {
        return episodes.filter {
            guard let lhs = $0.mediaMetadata[MPMediaItemPropertySeason] as? Int else { return false }
            return lhs == season
        }.sorted {
            guard let lhs = $0.0.mediaMetadata[MPMediaItemPropertyEpisode] as? Int, let rhs = $0.1.mediaMetadata[MPMediaItemPropertyEpisode] as? Int else { return false }
            return lhs < rhs
        }
    }
}
