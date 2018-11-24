

import UIKit
import struct PopcornKit.Subtitle

protocol OptionsViewControllerDelegate: class {
    func didSelectSubtitle(_ subtitle: Subtitle?)
    func didSelectSubtitleDelay(_ delay: Int)
    func didSelectEncoding(_ encoding: String)
    func didSelectAudioDelay(_ delay: Int)
}


class OptionsTableViewController: UITableViewController {
    
    weak var delegate: OptionsViewControllerDelegate?
    
    var allSubtitles = Dictionary<String, [Subtitle]>()
    
    var currentSubtitle: Subtitle?
    var currentSubtitleDelay = 0
    var currentAudioDelay = 0
    
    @IBAction func cancel() {
        dismiss(animated: true)
    }
    
    // MARK: - Table view delegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)!
        if cell.imageView?.image != nil // If selected cell is already the current subtitle, the user wants to remove subtitles
        {
            currentSubtitle = nil
        } else {
            currentSubtitle = Array(allSubtitles[cell.textLabel?.text ?? "English"]!).first
        }
       
        delegate?.didSelectSubtitle(currentSubtitle)
        tableView.deselectRow(at: indexPath, animated: true)
        tableView.reloadData()
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return "Audio Delay".localized
        case 1:
            return "Subtitle Delay".localized
        case 2:
            return "Subtitle Language".localized
        default:
            return nil
        }
    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 1
        case 1:
            return 1
        case 2:
            return allSubtitles.keys.count
        default:
            return 0
        }
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell
        
        switch indexPath.section {
        case 0:
            cell = tableView.dequeueReusableCell(withIdentifier: "delayCell", for: indexPath)
            cell.textLabel?.text = (currentAudioDelay > 0 ? "+" : "") + NumberFormatter.localizedString(from: NSNumber(value: currentAudioDelay), number: .decimal)
        case 1:
            cell = tableView.dequeueReusableCell(withIdentifier: "delayCell", for: indexPath)
            cell.textLabel?.text = (currentSubtitleDelay > 0 ? "+" : "") + NumberFormatter.localizedString(from: NSNumber(value: currentSubtitleDelay), number: .decimal)
        case 2:
            cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
            cell.textLabel?.text = Array(allSubtitles.keys)[indexPath.row]
            if let currentSubtitle = currentSubtitle, currentSubtitle.link == Array(allSubtitles[cell.textLabel!.text!]!).first!.link {
                cell.accessoryType = .detailButton
                cell.imageView?.image = "✔️".image()
            } else {
                cell.accessoryType = .none
                cell.imageView?.image = nil
            }
        default:
            return UITableViewCell()
        }
        
        return cell
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showExtendedSubtitles"{
            if let destination = segue.destination as? ExtendedSubtitleTableViewController{
                destination.allSubtitles = allSubtitles
                destination.currentSubtitle = currentSubtitle
                destination.delegate = delegate
            }
        }
    }
}
