

import Foundation
import UIKit

class AudioViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet var languageTableView: UITableView!
    @IBOutlet var delayTableView: UITableView!
    
    var languages = [String]()
    var currentLanguage: String!
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return languages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = languages[indexPath.row]
        cell.accessoryType = currentLanguage == languages[indexPath.row] ? .checkmark : .none
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch tableView {
        case languageTableView:
            return "Language"
        case delayTableView:
            return "Delay"
        default:
            return nil
        }
    }
    
    func tableView(_ tableView: UITableView, didUpdateFocusIn context: UITableViewFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        if let indexPath = context.nextFocusedIndexPath, let cell = tableView.cellForRow(at: indexPath) {
            cell.textLabel?.textColor = UIColor.white
            tableView.scrollToRow(at: tableView.indexPath(for: cell)!, at: .none, animated: true)
        }
        if let indexPath = context.previouslyFocusedIndexPath, let cell = tableView.cellForRow(at: indexPath) {
            cell.textLabel?.textColor = UIColor.lightGray
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        guard let header = view as? UITableViewHeaderFooterView else { return }
        header.textLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        header.textLabel?.alpha = 0.45
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch tableView {
        case languageTableView:
            if currentLanguage == languages[indexPath.row] { // If row was already selected, user wants to remove the selection.
                currentLanguage = nil
            } else {
                currentLanguage = languages[indexPath.row]
            }
        case delayTableView:
            break
        default:
            break
        }
        tableView.reloadData()
    }
}
