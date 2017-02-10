

import UIKit
import PopcornKit

protocol OptionsViewControllerDelegate: class {
    func didSelectSubtitle(_ subtitle: Subtitle?)
    func didSelectSubtitleDelay(_ delay: Int)
    func didSelectEncoding(_ encoding: String)
    func didSelectAudioDelay(_ delay: Int)
}


class OptionsTableViewController: UITableViewController {
    
    weak var delegate: OptionsViewControllerDelegate?
    
    var subtitles = [Subtitle]()
    
    var currentSubtitle: Subtitle?
    var currentSubtitleDelay = 0
    var currentAudioDelay = 0
    
    @IBAction func cancel() {
        dismiss(animated: true)
    }
    
    // MARK: - Table view delegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)!
        if cell.accessoryType == .checkmark // If selected cell is already the current subtitle, the user wants to remove subtitles
        {
            currentSubtitle = nil
        } else {
            currentSubtitle = subtitles[indexPath.row]
        }
       
        delegate?.didSelectSubtitle(currentSubtitle)
        tableView.deselectRow(at: indexPath, animated: true)
        tableView.reloadData()
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return "Audio Delay"
        case 1:
            return "Subtitle Delay"
        case 2:
            return "Subtitle Language"
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
            return subtitles.count
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
            cell.textLabel?.text = (currentAudioDelay > 0 ? "+" : "") + "\(currentAudioDelay).0"
        case 1:
            cell = tableView.dequeueReusableCell(withIdentifier: "delayCell", for: indexPath)
            cell.textLabel?.text = (currentSubtitleDelay > 0 ? "+" : "") + "\(currentSubtitleDelay).0"
        case 2:
            cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
            cell.textLabel?.text = subtitles[indexPath.row].language
            if let currentSubtitle = currentSubtitle, currentSubtitle.link == subtitles[indexPath.row].link {
                cell.accessoryType = .checkmark
            } else {
                cell.accessoryType = .none
            }
        default:
            return UITableViewCell()
        }
        
        return cell
    }
}
