

import Foundation
import PopcornKit
import AVFoundation.AVFAudio.AVAudioSession

enum EqualizerProfiles: UInt32 {
    case fullDynamicRange = 0
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

    let delays = [Int](-60...60)
    let sounds = EqualizerProfiles.array
    
    var currentDelay = 0
    var currentSound: EqualizerProfiles = .fullDynamicRange
    
    var manager = AVSpeakerManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(pickableRoutesDidChange), name: .AVSpeakerManagerPickableRoutesDidChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(pickableRoutesDidChange), name: .AVAudioSessionRouteChange, object: nil)
    }
    
    func pickableRoutesDidChange() {
        thirdTableView?.reloadData()
    }
    
    
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
            let route = manager.speakerRoutes[indexPath.row]
            manager.select(route: route)
        default:
            break
        }
        tableView.reloadData()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
