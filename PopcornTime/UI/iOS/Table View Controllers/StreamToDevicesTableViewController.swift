

import UIKit
import MediaPlayer
import GoogleCast
import PopcornKit

class StreamToDevicesTableViewController: UITableViewController, GCKDeviceScannerListener, ConnectDevicesDelegate, StreamToDevicesTableViewCellDelegate {
    
    var airPlayDevices = [MPAVRoute]()
    var googleCastDevices = [GCKDevice]()
    
    var airPlayManager: AirPlayManager!
    var googleCastManager: GoogleCastManager!
    
    var onlyShowCastDevices: Bool = false
    var castMetadata: CastMetaData?
    
    
    override func viewDidLoad() {
        if !onlyShowCastDevices {
            airPlayManager = AirPlayManager()
            airPlayManager.delegate = self
        }
        googleCastManager = GoogleCastManager()
        googleCastManager.delegate = self
    }
    
    func updateTableView(dataSource newDataSource: [Any], updateType: TableViewUpdates, indexPaths: [IndexPath]?) {
        self.tableView.beginUpdates()
        if let dataSource = newDataSource as? [GCKDevice] {
            googleCastDevices = dataSource
        } else {
            airPlayDevices = newDataSource as! [MPAVRoute]
        }
        switch updateType {
        case .insert:
            self.tableView.insertRows(at: indexPaths!, with: .middle)
            fallthrough
        case .reload:
            if let visibleIndexPaths = self.tableView.indexPathsForVisibleRows {
                self.tableView.reloadRows(at: visibleIndexPaths, with: .none)
            }
        case .delete:
            self.tableView.deleteRows(at: indexPaths!, with: .middle)
        }
        self.tableView.endUpdates()
    }
    

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        if airPlayDevices.isEmpty && googleCastDevices.isEmpty {
            let label = UILabel(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
            label.text = "No devices available"
            label.textColor = .lightGray
            label.numberOfLines = 0
            label.textAlignment = .center
            label.sizeToFit()
            tableView.backgroundView = label
            tableView.separatorStyle = .none
        } else {
            tableView.backgroundView = nil
            tableView.separatorStyle = .singleLine
        }
        return 2
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return airPlayDevices.isEmpty ? nil : "AirPlay"
        case 1:
            return googleCastDevices.isEmpty ? nil : "Google Cast"
        default:
            return nil
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? airPlayDevices.count : googleCastDevices.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! StreamToDevicesTableViewCell
        if indexPath.section == 0 {
            let route = airPlayDevices[indexPath.row]
            cell.isPicked = route.isPicked!
            if let mirroringRoute = route.wirelessDisplayRoute, mirroringRoute.isPicked! {
                cell.isPicked = true
                cell.mirroringSwitch?.setOn(true, animated: true)
            } else {
                cell.mirroringSwitch?.setOn(false, animated: false)
            }
            cell.titleLabel?.text = route.routeName
            //cell.iconImageView?.image = route.routeImage
            cell.delegate = self
        } else {
            cell.titleLabel?.text = googleCastDevices[indexPath.row].friendlyName
            cell.iconImageView?.image = UIImage(named: "CastOff")
            if let session = GCKCastContext.sharedInstance().sessionManager.currentSession {
                cell.isPicked = googleCastDevices[indexPath.row] == session.device
            } else {
                cell.isPicked = false
            }
        }
        return cell
    }
    
    func routingCell(_ cell: StreamToDevicesTableViewCell, mirroringSwitchValueDidChange on: Bool) {
        guard let index = tableView.indexPath(for: cell)?.row else { return }
        let route = airPlayDevices[index]
        airPlayManager.didSelectRoute(on ? route.wirelessDisplayRoute ?? route : route)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            airPlayManager.didSelectRoute(airPlayDevices[indexPath.row])
        } else {
            googleCastManager.didSelectRoute(googleCastDevices[indexPath.row], castMetadata: castMetadata)
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 && airPlayDevices.isEmpty {
            return .leastNormalMagnitude
        } else if section == 1 && googleCastDevices.isEmpty {
            return .leastNormalMagnitude
        }
        return 18
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 {
            let route = airPlayDevices[indexPath.row]
            if let wirelessRoute = route.wirelessDisplayRoute, (route.isPicked! || wirelessRoute.isPicked!) {
                return 88
            }
        }
        return 44
    }
    
    func didConnectToDevice(deviceIsChromecast chromecast: Bool) {
        if chromecast, let playerViewController = presentingViewController as? PCTPlayerViewController {
            dismiss(animated: false, completion: {
                playerViewController.delegate?.presentCastPlayer(playerViewController.media, videoFilePath: playerViewController.directory, startPosition: TimeInterval(playerViewController.progressBar.progress))
            })
        } else {
           dismiss(animated: true, completion: nil)
        }
    }
}
