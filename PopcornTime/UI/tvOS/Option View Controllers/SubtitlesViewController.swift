

import UIKit
import struct PopcornKit.Subtitle
import PopcornTorrent

class SubtitlesViewController: OptionsStackViewController, UITableViewDataSource {
    var subtitleLangs = [String]()
    var sortedSubtitles = [String: [Subtitle]]()
    var subtitles: [String: [Subtitle]] {
        get {
            return sortedSubtitles
        }
        set {
            let name = withUnsafePointer(to: &PTTorrentStreamer.shared().torrentStatus.videoFileName) {
                $0.withMemoryRebound(to: UInt8.self, capacity: MemoryLayout.size(ofValue: PTTorrentStreamer.shared().torrentStatus.videoFileName)) {
                    String(cString: $0)
                }
            }
            subtitleLangs = Array(newValue.keys)
            sortedSubtitles.removeAll()

            for key in newValue.keys {
                sortedSubtitles[key] = newValue[key]?.sorted(by: { (sub1, sub2) -> Bool in
                    stringDifference(sub1.name, toString: name) < stringDifference(sub2.name, toString: name)
                })
            }
        }
    }
    let encodings = SubtitleSettings.encodings
    let delays = [Int](-60...60)
    
    var currentSubtitle: Subtitle?
    var currentDelay = 0
    var currentEncoding = SubtitleSettings.shared.encoding {
        didSet {
            let subtitle = SubtitleSettings.shared
            subtitle.encoding = currentEncoding
            subtitle.save()
        }
    }
    
    func stringDifference(_ str1: String, toString str2: String) -> Int {
        let str1Parts = str1.components(separatedBy: CharacterSet.alphanumerics.inverted)
        let str2Parts = str2.components(separatedBy: CharacterSet.alphanumerics.inverted)
        
        var rank = 0
        for part in str1Parts {
            if str2Parts.contains(part) {
                rank += 1
            }
        }
        return str1Parts.count - rank
    }
    

    // MARK: Table view data source
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        switch tableView {
        case firstTableView:
            let lang = subtitleLangs[indexPath.section]
            let subtitle = sortedSubtitles[lang]![indexPath.row]
            cell.textLabel?.text = subtitle.cleanName
            cell.accessoryType = currentSubtitle == subtitle ? .checkmark : .none
        case secondTableView:
            let delay = delays[indexPath.row]
            cell.textLabel?.text = (delay > 0 ? "+" : "") + NumberFormatter.localizedString(from: NSNumber(value: delay), number: .decimal)
            cell.accessoryType = currentDelay == delay ? .checkmark : .none
        case thirdTableView:
            cell.textLabel?.text = Array(encodings.keys)[indexPath.row]
            cell.accessoryType = currentEncoding == Array(encodings.values)[indexPath.row] ? .checkmark : .none
        default:
            break
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch tableView {
        case firstTableView:
            return sortedSubtitles[subtitleLangs[section]]?.first?.language
        case secondTableView:
            return "Delay".localized
        case thirdTableView:
            return "Encoding".localized
        default:
            return nil
        }
    }
    
    // MARK: Table view delegate
    
    func numberOfSections(in tableView: UITableView) -> Int {
        tableView.backgroundView = nil
        if tableView == firstTableView {
            if subtitles.isEmpty {
                let label = UILabel(frame: CGRect(origin: .zero, size: CGSize(width: 200.0, height: 20)))
                tableView.backgroundView = label
                label.text = "No subtitles available.".localized
                label.textColor = UIColor(white: 1.0, alpha: 0.5)
                label.textAlignment = .center
                label.font = UIFont.systemFont(ofSize: 35.0, weight: UIFontWeightMedium)
                label.center = tableView.center
                label.sizeToFit()
            } else {
                return subtitleLangs.count
            }
        }
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch tableView {
        case firstTableView:
            let lang = subtitleLangs[section]
            return sortedSubtitles[lang]!.count
        case secondTableView:
            return delays.count
        case thirdTableView:
            return encodings.count
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch tableView {
        case firstTableView:
            let lang = subtitleLangs[indexPath.section]
            let subtitle = sortedSubtitles[lang]![indexPath.row]
            if currentSubtitle == subtitle { // If row was already selected, user wants to remove the selection.
                currentSubtitle = nil
            } else {
                currentSubtitle = subtitle
            }
            delegate?.didSelectSubtitle(currentSubtitle)
        case secondTableView:
            currentDelay = delays[indexPath.row]
            delegate?.didSelectSubtitleDelay(currentDelay)
        case thirdTableView:
            currentEncoding = Array(encodings.values)[indexPath.row]
            delegate?.didSelectEncoding(currentEncoding)
        default:
            break
        }
        tableView.reloadData()
    }
}
