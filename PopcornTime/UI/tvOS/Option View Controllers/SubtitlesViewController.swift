

import UIKit
import struct PopcornKit.Subtitle

protocol SubtitlesViewControllerDelegate: class {
    func didSelectSubtitle(_ subtitle: Subtitle?)
}

class SubtitlesViewController: OptionsStackViewController,SubtitlesViewControllerDelegate, UITableViewDataSource {
    
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
    
    private var subtitlesInView:[Subtitle] = Array()
    
    // MARK: Long press gesture set up
    
    override func viewDidLoad() {
        if allSubtitles.count > 0 {
            subtitlesInView += [currentSubtitle ?? allSubtitles["English"]!.first!,Subtitle(name: "", language: "Select Other", link: "", ISO639: "", rating: 0.0)]
            subtitlesInView = (SubtitleSettings.shared.subtitlesSelectedForVideo as! [Subtitle])
        }
        super.viewDidLoad()
    }

    // MARK: Table view data source
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        switch tableView {
        case firstTableView:
                cell.textLabel?.text = subtitlesInView[indexPath.row].language
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
        }else if tableView == firstTableView && subtitlesInView.isEmpty{
            subtitlesInView = [currentSubtitle ?? allSubtitles["English"]!.first!,Subtitle(name: "", language: "Select Other", link: "", ISO639: "", rating: 0.0)]
            for unknownSubtitle in SubtitleSettings.shared.subtitlesSelectedForVideo{
                if let subtitle = unknownSubtitle as? Subtitle{
                    if !subtitlesInView.contains(subtitle){
                        subtitlesInView.insert(subtitle, at: 0)
                    }
                }
            }
        }
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch tableView {
        case firstTableView:
            return subtitlesInView.count
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
            if indexPath.row != (tableView.numberOfRows(inSection: 0) - 1) {
                if currentSubtitle?.language == cell?.textLabel?.text && currentSubtitle == allSubtitles[cell?.textLabel?.text ?? ""]?.first{ // If row was already selected, user wants to remove the selection.
                    currentSubtitle = nil
                }else if currentSubtitle?.language != cell?.textLabel?.text {
                    currentSubtitle = (subtitlesInView.compactMap{ return $0.language == cell?.textLabel?.text ? $0 : nil }).first
                }
                delegate?.didSelectSubtitle(currentSubtitle)
            }else{
                guard let extendedView = storyboard?.instantiateViewController(withIdentifier: "ExtendedSubtitleSelectionView") as? ExtendedSubtitleViewController
                    else{
                        return
                }
                extendedView.delegate = self
                extendedView.allSubtitles = allSubtitles
                extendedView.currentSubtitle = currentSubtitle
                present(extendedView, animated: true)
            }
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
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
    }
    
    
    func didSelectSubtitle(_ subtitle: Subtitle?) {
        self.currentSubtitle = subtitle
        subtitlesInView.insert(subtitle!, at: 0)
        SubtitleSettings.shared.subtitlesSelectedForVideo.append(subtitle! as Any)
        delegate?.didSelectSubtitle(subtitle)
    }
}
