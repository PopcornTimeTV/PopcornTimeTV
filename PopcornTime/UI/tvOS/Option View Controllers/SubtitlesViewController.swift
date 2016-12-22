

import UIKit
import PopcornKit

class SubtitlesViewController: OptionsStackViewController, UITableViewDataSource {
    
    override var activeTabBarButton: UIView {
        return tabBar.subviews.first(where: {$0 is UIScrollView})?.subviews[safe: 1] ?? UIView()
    }
    
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
    let delays: [Int] = {
        var delays = [Int]()
        for delay in -5...5 {
            delays.append(delay)
        }
        return delays
    }()
    
    var currentSubtitle: Subtitle?
    var currentDelay = 0
    var currentEncoding = SubtitleSettings().encoding {
        didSet {
            let subtitle = SubtitleSettings()
            subtitle.encoding = currentEncoding
            subtitle.save()
        }
    }
    

    // MARK: Table view data source
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        switch tableView {
        case firstTableView:
            cell.textLabel?.text = subtitles[indexPath.row].language
            cell.accessoryType = currentSubtitle == subtitles[indexPath.row] ? .checkmark : .none
        case secondTableView:
            let delay = delays[indexPath.row]
            cell.textLabel?.text = (delay > 0 ? "+" : "") + "\(delay).0"
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
            return "Language"
        case secondTableView:
            return "Delay"
        case thirdTableView:
            return "Encoding"
        default:
            return nil
        }
    }
    
    // MARK: Table view delegate
    
    func numberOfSections(in tableView: UITableView) -> Int {
        tableView.backgroundView = nil
        if tableView == firstTableView && subtitles.isEmpty {
            let label = UILabel(frame: CGRect(origin: .zero, size: CGSize(width: 200.0, height: 20)))
            tableView.backgroundView = label
            label.text = "No subtitles available."
            label.textColor = UIColor(white: 1.0, alpha: 0.5)
            label.textAlignment = .center
            label.font = UIFont.systemFont(ofSize: 35.0, weight: UIFontWeightMedium)
            label.center = tableView.center
            label.sizeToFit()
        }
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch tableView {
        case firstTableView:
            return subtitles.count
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
            if currentSubtitle == subtitles[indexPath.row] { // If row was already selected, user wants to remove the selection.
                currentSubtitle = nil
            } else {
                currentSubtitle = subtitles[indexPath.row]
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
