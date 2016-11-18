

import UIKit
import MediaPlayer
import GoogleCast
import PopcornKit

class StreamToDevicesTableViewController: UITableViewController, GCKDeviceScannerListener, ConnectDevicesProtocol {
    
    var airPlayDevices = [MPAVRouteProtocol]()
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
    
    @IBAction func mirroringChanged(_ sender: UISwitch) {
        let selectedRoute = airPlayDevices[tableView.indexPath(for: sender.superview?.superview as! AirPlayTableViewCell)!.row]
        airPlayManager.mirrorChanged(sender, selectedRoute: selectedRoute)
    }
    
    func updateTableView(dataSource newDataSource: [AnyObject], updateType: TableViewUpdates, indexPaths: [IndexPath]?) {
        self.tableView.beginUpdates()
        if let dataSource = newDataSource as? [GCKDevice] {
            googleCastDevices = dataSource
        } else {
            airPlayDevices = newDataSource as! [MPAVRouteProtocol]
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
            let label = UILabel(frame: CGRect(x: 0,y: 0,width: 100,height: 100))
            label.text = "No devices available"
            label.textColor = UIColor.lightGray
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
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! AirPlayTableViewCell
        if indexPath.section == 0 {
            cell.picked = airPlayDevices[indexPath.row].isPicked!()
            if let mirroringRoute = airPlayDevices[indexPath.row].wirelessDisplayRoute?() , mirroringRoute.isPicked!() {
                cell.picked = true
                cell.mirrorSwitch?.setOn(true, animated: true)
            } else {
                cell.mirrorSwitch?.setOn(false, animated: false)
            }
            cell.titleLabel?.text = airPlayDevices[indexPath.row].routeName!()
            cell.airImageView?.image = airPlayManager.airPlayItemImage(indexPath.row)
        } else {
            cell.titleLabel?.text = googleCastDevices[indexPath.row].friendlyName
            cell.airImageView?.image = UIImage(named: "CastOff")
            if let session = GCKCastContext.sharedInstance().sessionManager.currentSession {
                cell.picked = googleCastDevices[indexPath.row] == session.device
            } else {
                cell.picked = false
            }
        }
        return cell
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
            return CGFloat.leastNormalMagnitude
        } else if section == 1 && googleCastDevices.isEmpty {
            return CGFloat.leastNormalMagnitude
        }
        return 18
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 {
            if let _ = airPlayDevices[indexPath.row].wirelessDisplayRoute?() , airPlayDevices[indexPath.row].isPicked!() || airPlayDevices[indexPath.row].wirelessDisplayRoute!().isPicked!() {
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
