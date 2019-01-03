

import UIKit
import struct PopcornKit.Subtitle

protocol SubtitlesViewControllerDelegate: class {
    func didSelectSubtitle(_ subtitle: Subtitle?)
}

class SubtitlesViewController: OptionsStackViewController,SubtitlesViewControllerDelegate, UITableViewDataSource {
    
    var subtitles = Dictionary<String, [Subtitle]>()
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
        if tableView == firstTableView && subtitles.isEmpty {
            let label = UILabel(frame: CGRect(origin: .zero, size: CGSize(width: 200.0, height: 20)))
            tableView.backgroundView = label
            label.text = "No subtitles available.".localized
            label.textColor = UIColor(white: 1.0, alpha: 0.5)
            label.textAlignment = .center
            label.font = UIFont.systemFont(ofSize: 35.0, weight: UIFont.Weight.medium)
            label.center = tableView.center
            label.sizeToFit()
        }else if tableView == firstTableView && subtitlesInView.isEmpty{
            subtitlesInView = [currentSubtitle ?? subtitles[Locale.current.localizedString(forLanguageCode: "en")!.localizedCapitalized]!.first!,Subtitle(name: "", language: "Select Other".localized, link: "", ISO639: "", rating: 0.0)]
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
                if currentSubtitle?.language == cell?.textLabel?.text && currentSubtitle == subtitles[cell?.textLabel?.text ?? ""]?.first{ // If row was already selected, user wants to remove the selection.
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
                extendedView.subtitles = subtitles
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

        for i in 0..<SubtitleSettings.shared.subtitlesSelectedForVideo.count{
            if let savedSubtitle = SubtitleSettings.shared.subtitlesSelectedForVideo[i] as? Subtitle{
                if savedSubtitle.language == subtitle?.language{// do we have a sub with the same language in permanent storage
                    SubtitleSettings.shared.subtitlesSelectedForVideo.replaceSubrange(i...i, with: [subtitle as Any])//replace the one we have with the latest one
                    let index = subtitlesInView.firstIndex(of: savedSubtitle)!
                    subtitlesInView[index] = subtitle!
                    delegate?.didSelectSubtitle(subtitle)
                    return
                }
            }
        }
        if !subtitlesInView.contains(subtitle!){// does the subtitlesinview already have our sub if no enter
            for savedSubtitle in subtitlesInView{
                if subtitle!.language == savedSubtitle.language{// do we have a sub with the same language
                    let index = subtitlesInView.firstIndex(of: savedSubtitle)!
                    subtitlesInView[index] = subtitle!//switch out the one with the same language with our latest one
                    SubtitleSettings.shared.subtitlesSelectedForVideo.append(subtitle! as Any)//add it to our permanent list
                    break
                }
                if savedSubtitle == subtitlesInView.last{//if we do not have a sub with the same language
                    subtitlesInView.insert(subtitle!, at: 0) //add the latest selected
                    SubtitleSettings.shared.subtitlesSelectedForVideo.append(subtitle! as Any)
                }
            }
        }else{// we have the sub in the subtitlesinview but not in permanent storage
            SubtitleSettings.shared.subtitlesSelectedForVideo.append(subtitle! as Any)
        }
        
        
        delegate?.didSelectSubtitle(subtitle)//notify the pctplayerviewcontroller
    }
}
