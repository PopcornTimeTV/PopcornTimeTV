

import UIKit
import PopcornKit

protocol OptionsViewControllerDelegate: class {
    func didSelectSubtitle(_ subtitle: Subtitle?)
}

class SubtitlesViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    weak var delegate: OptionsViewControllerDelegate?
    
    @IBOutlet var firstTableView: UITableView!
    @IBOutlet var secondTableView: UITableView!
    @IBOutlet var thirdTableView: UITableView!
    
    var subtitles = [Subtitle]()
    let encodings: [String: String] = {
        guard let path = Bundle.main.path(forResource: "EncodingTypes", ofType: "plist"),
            let labels = NSDictionary(contentsOfFile: path) as? [String: [String]],
            let titles = labels["Titles"],
            let values = labels["Values"],
            titles.count == values.count else { return [String: String]() }
        var dict = [String: String]()
        for (index, key) in titles.enumerated() {
            dict[key] = values[index]
        }
        return dict
    }()
    let sizes: [String: Float] = ["Small (46pts)" : 20.0, "Medium (56pts)" : 16.0, "Medium Large (66pts)" : 12.0, "Large (96pts)" : 6.0]
    
    var currentSubtitle: Subtitle?
    var currentEncoding = SubtitleSettings().encoding {
        didSet {
            let subtitle = SubtitleSettings()
            subtitle.encoding = currentEncoding
            subtitle.save()
        }
    }
    var currentSize = SubtitleSettings().fontSize {
        didSet {
            let subtitle = SubtitleSettings()
            subtitle.fontSize = currentSize
            subtitle.save()
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        for tableView in [firstTableView, secondTableView, thirdTableView] {
            tableView?.mask = nil
            tableView?.clipsToBounds = true
        }
    }


    // MARK: Table view data source
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell
        switch tableView {
        case firstTableView:
            cell = tableView.dequeueReusableCell(withIdentifier: "firstTableViewCell", for: indexPath)
            cell.textLabel?.text = subtitles[indexPath.row].language
            cell.accessoryType = currentSubtitle == subtitles[indexPath.row] ? .checkmark : .none
        case secondTableView:
            cell = tableView.dequeueReusableCell(withIdentifier: "secondTableViewCell", for: indexPath)
            cell.textLabel?.text = Array(sizes.keys)[indexPath.row]
            cell.accessoryType = currentSize == Array(sizes.values)[indexPath.row] ? .checkmark : .none
        case thirdTableView:
            cell = tableView.dequeueReusableCell(withIdentifier: "thirdTableViewCell", for: indexPath)
            cell.textLabel?.text = Array(encodings.keys)[indexPath.row]
            cell.accessoryType = currentEncoding == Array(encodings.values)[indexPath.row] ? .checkmark : .none
        default:
            cell = UITableViewCell()
            cell.accessoryType = .none
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch tableView {
        case firstTableView:
            return "Language"
        case secondTableView:
            return "Size"
        case thirdTableView:
            return "Encoding"
        default:
            return nil
        }
    }
    
    // MARK: Table view delegate
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch tableView {
        case firstTableView:
            return subtitles.count
        case secondTableView:
            return sizes.count
        case thirdTableView:
            return encodings.count
        default:
            return 0
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
//    
//    override func shouldUpdateFocus(in context: UIFocusUpdateContext) -> Bool {
//        return !(context.nextFocusedView is UITabBar) // Stops focus sticking to UITabbar
//    }
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        guard let header = view as? UITableViewHeaderFooterView else { return }
        header.textLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        header.textLabel?.alpha = 0.45
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch tableView {
        case firstTableView:
            if currentSubtitle == subtitles[indexPath.row] { // If row was already selected, user wants to remove the selection.
                currentSubtitle = nil
            } else {
                currentSubtitle = subtitles[indexPath.row]
            }
            delegate?.didSelectSubtitle(currentSubtitle)
        case secondTableView:
            currentSize = Array(sizes.values)[indexPath.row]
        case thirdTableView:
            currentEncoding = Array(encodings.values)[indexPath.row]
        default:
            break
        }
        tableView.reloadData()
    }
}
