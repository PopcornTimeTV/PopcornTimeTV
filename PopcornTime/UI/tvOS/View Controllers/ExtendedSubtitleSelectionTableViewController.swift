
import UIKit
import struct PopcornKit.Subtitle

class ExtendedSubtitleSelectionTableViewController: UITableViewController {

    var subtitles = Dictionary<String, [Subtitle]>()
    var currentSubtitle:Subtitle?
    var delegate:SubtitlesViewControllerDelegate?
    
    private var previousCell:UITableViewCell?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // Always 2 sections, the selection section and the subtitles section
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        }else{
            return currentSubtitle != nil ? Array(subtitles[currentSubtitle!.language]!).count : 0
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell:UITableViewCell
        
        if indexPath.section == 0{
            cell = tableView.dequeueReusableCell(withIdentifier: "LangCell")!
            cell.detailTextLabel?.text = currentSubtitle?.language ?? "None".localized
        }else{
            cell = tableView.dequeueReusableCell(withIdentifier: "SubCell")!
            let subtitle = Array(subtitles[currentSubtitle?.language ?? Locale.current.localizedString(forLanguageCode: "en")!]!)[indexPath.row]
            cell.detailTextLabel?.text = subtitle.language
            cell.textLabel?.text = subtitle.name
            cell.accessoryType = currentSubtitle?.name == subtitle.name ? .checkmark : .none
            currentSubtitle?.name == subtitle.name ? previousCell = cell : ()
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)
        if indexPath.section == 0 {
            let alertController = UIAlertController(title: "Select Language".localized, message: nil, preferredStyle: .actionSheet)
            
            let allLanguages = Array(subtitles.keys).sorted()
            for (language) in allLanguages{
                        let action = UIAlertAction(title: language, style: .default) { _ in
                            self.currentSubtitle = self.subtitles[language]?.first
                            cell?.detailTextLabel?.text = language
                            tableView.reloadSections(IndexSet(arrayLiteral: 1), with: .fade)
                            self.delegate?.didSelectSubtitle(self.currentSubtitle)
                        }
                        alertController.addAction(action)
            }
            alertController.addAction(UIAlertAction(title: "Cancel".localized, style: .cancel, handler: nil))
            alertController.show(animated: true)
        }else{
            self.currentSubtitle = Array(subtitles[currentSubtitle!.language]!)[indexPath.row]
            previousCell?.accessoryType = .none
            cell?.accessoryType = .checkmark
            previousCell = cell
            delegate?.didSelectSubtitle(currentSubtitle)
        }
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 1 {
            return "Available Subtitles".localized
        }
        return ""
    }
}
