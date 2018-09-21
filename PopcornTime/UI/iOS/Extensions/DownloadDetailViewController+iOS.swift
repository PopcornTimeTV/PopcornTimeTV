

import Foundation
import MediaPlayer.MPMediaItem
import class PopcornTorrent.PTTorrentDownloadManager

extension DownloadDetailViewController: DownloadDetailTableViewCellDelegate {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = show.title
        navigationItem.rightBarButtonItem = editButtonItem
        tableView.tableFooterView = UIView()
        tableView.register(UINib(nibName: "DownloadTableViewHeader", bundle: nil), forHeaderFooterViewReuseIdentifier: "header")
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return seasons.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource(for: seasons[section]).count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell") as! DownloadDetailTableViewCell
        let download = dataSource(for: seasons[indexPath.section])[indexPath.row]
        
        cell.delegate = self
        cell.downloadButton.downloadState = DownloadButton.ButtonState(download.downloadStatus)
        cell.downloadButton.invalidateAppearance()
        
        let episodeNumber = NumberFormatter.localizedString(from: NSNumber(value: download.mediaMetadata[MPMediaItemPropertyEpisode] as? Int ?? 0), number: .none)
        let episodeTitle = download.mediaMetadata[MPMediaItemPropertyTitle] as? String ?? ""
        
        cell.textLabel?.text = "\(episodeNumber). \(episodeTitle)"
        cell.detailTextLabel?.text = download.fileSize.stringValue
        
        if let image = download.mediaMetadata[MPMediaItemPropertyBackgroundArtwork] as? String, let url = URL(string: image) {
            cell.imageView?.af_setImage(withURL: url)
        } else {
            cell.imageView?.image = UIImage(named: "Episode Placeholder")
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: "header")
        let label = header?.viewWithTag(1) as? UILabel
        
        let localizedSeason = NumberFormatter.localizedString(from: NSNumber(value: seasons[section]), number: .none)
        label?.text = "Season".localized + " \(localizedSeason)"
        
        return header
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 40
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete else { return }
        
        let download = dataSource(for: seasons[indexPath.section])[indexPath.row]
        
        
        
        tableView.beginUpdates()
        if dataSource(for: seasons[indexPath.section]).count == 1{
            tableView.deleteSections(IndexSet(integer: indexPath.section), with: .fade)
            self.navigationController?.pop(animated: true)
        }else{
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
        PTTorrentDownloadManager.shared().delete(download)
        tableView.endUpdates()
    }
    
    func cell(_ cell: DownloadDetailTableViewCell, accessoryButtonPressed button: DownloadButton) {
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        
        let download = dataSource(for: seasons[indexPath.section])[indexPath.row]
        
        AppDelegate.shared.downloadButton(button, wasPressedWith: download) { [unowned self] in
            if self.episodes.count == 0 && self.seasons.count == 1{
                self.tableView.deleteSections(IndexSet(integer: 1), with: .none)
            }
            self.tableView.reloadData()
        }
    }
}
