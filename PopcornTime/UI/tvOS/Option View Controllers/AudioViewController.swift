

import Foundation
import PopcornKit

enum EqualizerProfiles: UInt32 {
    case fullDynamicRange = 5
    case reduceLoudSounds = 15
    
    static let array = [fullDynamicRange, reduceLoudSounds]
    
    var localizedString: String {
        switch self {
        case .fullDynamicRange:
            return "Full Dynamic Range".localized
        case .reduceLoudSounds:
            return "Reduce Loud Sounds".localized
        }
    }
}

class AudioViewController: OptionsStackViewController, UITableViewDataSource {
    
    override var activeTabBarButton: UIView {
        return tabBar.subviews.first(where: {$0 is UIScrollView})?.subviews[safe: 2] ?? UIView()
    }

    let delays: [Int] = {
        var delays = [Int]()
        for delay in -60...60 {
            delays.append(delay)
        }
        return delays
    }()
    let sounds = EqualizerProfiles.array
    
    var currentSpeaker: AVAudioRoute? = .default
    var currentDelay = 0
    var currentSound: EqualizerProfiles = .fullDynamicRange
    
    var manager = AVSpeakerManager()
    
    
    // MARK: Table view data source
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        switch tableView {
        case firstTableView:
            let delay = delays[indexPath.row]
            cell.textLabel?.text = (delay > 0 ? "+" : "") + NumberFormatter.localizedString(from: NSNumber(value: delay), number: .decimal)
            cell.accessoryType = currentDelay == delays[indexPath.row] ? .checkmark : .none
        case secondTableView:
            let sound = sounds[indexPath.row]
            cell.textLabel?.text = sound.localizedString
            cell.accessoryType = currentSound == sound ? .checkmark : .none
        case thirdTableView:
            let speaker = manager.speakerRoutes[indexPath.row]
            cell.textLabel?.text = speaker.name
            cell.accessoryType = speaker.isSelected ? .checkmark : .none
            cell.imageView?.image = UIImage(named: "Airplay TV")?.colored(cell.textLabel?.textColor)
        default:
            break
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch tableView {
        case firstTableView:
            return "Delay".localized
        case secondTableView:
            return "Sound".localized
        case thirdTableView:
            return "Speakers".localized
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
            return delays.count
        case secondTableView:
            return sounds.count
        case thirdTableView:
            return manager.speakerRoutes.count
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch tableView {
        case firstTableView:
            currentDelay = delays[indexPath.row]
            delegate?.didSelectAudioDelay(currentDelay)
        case secondTableView:
            currentSound = sounds[indexPath.row]
            delegate?.didSelectEqualizerProfile(currentSound)
        case thirdTableView:
            currentSpeaker = manager.speakerRoutes[indexPath.row]
            manager.select(route: currentSpeaker!)
        default:
            break
        }
        tableView.reloadData()
    }
}
