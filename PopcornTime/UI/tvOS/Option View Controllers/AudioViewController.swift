

import Foundation
import PopcornKit

class AudioViewController: OptionsStackViewController, UITableViewDataSource, AirPlayManagerDelegate {
    
    override var activeTabBarButton: UIView {
        return tabBar.subviews.first(where: {$0 is UIScrollView})?.subviews[safe: 2] ?? UIView()
    }
    
    var speakers = [MPAVRoute]()
    let delays: [Int] = {
        var delays = [Int]()
        for delay in -5...5 {
            delays.append(delay)
        }
        return delays
    }()
    let sounds = ["Full Dynamic Range", "Reduce Loud Sounds"]
    
    var currentSpeaker: MPAVRoute?
    var currentDelay = 0
    var currentSound = "Full Dynamic Range"
    
    var airPlayManager: AirPlayManager!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        airPlayManager = AirPlayManager()
        airPlayManager.delegate = self
    }
    
    
    func updateTableView(dataSource newDataSource: [Any], updateType: TableViewUpdates, indexPaths: [IndexPath]?) {
        
        thirdTableView.beginUpdates()
        switch updateType {
        case .insert:
            thirdTableView.insertRows(at: indexPaths!, with: .middle)
            fallthrough
        case .reload:
            if let visibleIndexPaths = thirdTableView.indexPathsForVisibleRows {
                thirdTableView.reloadRows(at: visibleIndexPaths, with: .none)
            }
        case .delete:
            thirdTableView.deleteRows(at: indexPaths!, with: .middle)
        }
        
        speakers = newDataSource as! [MPAVRoute]
        
        thirdTableView.endUpdates()
    }
    
    
    // MARK: Table view data source
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        switch tableView {
        case firstTableView:
            let delay = delays[indexPath.row]
            cell.textLabel?.text = (delay > 0 ? "+" : "") + "\(delay).0"
            cell.accessoryType = currentDelay == delays[indexPath.row] ? .checkmark : .none
        case secondTableView:
            let sound = sounds[indexPath.row]
            cell.textLabel?.text = sound
            cell.accessoryType = currentSound == sound ? .checkmark : .none
        case thirdTableView:
            let speaker = speakers[indexPath.row]
            cell.textLabel?.text = speaker.routeName
            cell.accessoryType = speaker.isPicked ? .checkmark : .none
        default:
            break
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch tableView {
        case firstTableView:
            return "Delay"
        case secondTableView:
            return "Sound"
        case thirdTableView:
            return "Speakers"
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
            return speakers.count
        default: return 0
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch tableView {
        case firstTableView:
            currentDelay = delays[indexPath.row]
            delegate?.didSelectAudioDelay(currentDelay)
        case secondTableView:
            currentSound = sounds[indexPath.row]
        case thirdTableView:
            currentSpeaker = speakers[indexPath.row]
            airPlayManager.didSelectRoute(currentSpeaker!)
        default:
            break
        }
        tableView.reloadData()
    }
}



