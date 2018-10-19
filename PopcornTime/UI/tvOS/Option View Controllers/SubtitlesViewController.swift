

import UIKit
import struct PopcornKit.Subtitle

class SubtitlesViewController: OptionsStackViewController, UITableViewDataSource {
    
    var subtitles = [Subtitle]()
    var allSubtitles = Dictionary<String, [Subtitle]>()
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
    
    // MARK: Long press gesture set up
    
    override func viewDidLoad() {
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(longPressDetected))
        longPressGesture.minimumPressDuration = 2.0
        self.firstTableView.addGestureRecognizer(longPressGesture)
        super.viewDidLoad()
    }
    
    
    @objc func longPressDetected(gestureRecognizer: UILongPressGestureRecognizer){
        if gestureRecognizer.state == .began{
            let p = gestureRecognizer.location(in: self.firstTableView)
            
            let indexPath = self.firstTableView.indexPathForRow(at: p)
            if indexPath != nil{
                //grab the subtitle language from the selected cell
                let cell = self.firstTableView.cellForRow(at: indexPath!)
                
                if currentSubtitle?.language != cell?.textLabel?.text ?? ""{
                    self.firstTableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
                }
                let alertController = UIAlertController(title: "Select Alternate Subtitle", message: nil, preferredStyle: .actionSheet)
                for (language,alternateSubtiles) in allSubtitles{
                    if language == cell?.textLabel?.text{
                        for subtitle in alternateSubtiles{
                            let action = UIAlertAction(title: subtitle.name, style: .default) { _ in
                                // subtitles api needs to be updated for this to work
                                self.currentSubtitle = subtitle
                                self.delegate?.didSelectSubtitle(subtitle)
                            }
                            alertController.addAction(action)
                        }
                    }
                }
                alertController.show(animated: true)
            }
        }
    }

    // MARK: Table view data source
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        switch tableView {
        case firstTableView:
            cell.textLabel?.text = Array(allSubtitles.keys)[indexPath.row]
            cell.accessoryType = currentSubtitle?.language == cell.textLabel?.text ? .checkmark : .none
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
            return "Language".localized
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
        if tableView == firstTableView && allSubtitles.isEmpty {
            let label = UILabel(frame: CGRect(origin: .zero, size: CGSize(width: 200.0, height: 20)))
            tableView.backgroundView = label
            label.text = "No subtitles available.".localized
            label.textColor = UIColor(white: 1.0, alpha: 0.5)
            label.textAlignment = .center
            label.font = UIFont.systemFont(ofSize: 35.0, weight: UIFont.Weight.medium)
            label.center = tableView.center
            label.sizeToFit()
        }
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch tableView {
        case firstTableView:
            return allSubtitles.keys.count
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
            let cell = firstTableView.cellForRow(at: indexPath)
            if currentSubtitle?.language == cell?.textLabel?.text && currentSubtitle == allSubtitles[cell?.textLabel?.text ?? ""]?.first{ // If row was already selected, user wants to remove the selection.
                currentSubtitle = nil
            } else if currentSubtitle?.language != cell?.textLabel?.text {
                currentSubtitle = allSubtitles[cell?.textLabel?.text ?? ""]?.first
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
