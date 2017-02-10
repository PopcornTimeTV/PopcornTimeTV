

import UIKit
import GoogleCast
import PopcornKit

class GoogleCastTableViewController: UITableViewController, GCKDeviceScannerListener, GoogleCastManagerDelegate {
    
    var dataSource = [GCKDevice]()
    var manager = GoogleCastManager()
    var castMetadata: CastMetaData?
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        preferredContentSize = tableView.contentSize
    }
    
    override func viewDidLoad() {
        manager.delegate = self
    }
    
    @IBAction func cancel() {
        dismiss(animated: true)
    }
    
    func updateTableView(dataSource newDataSource: [Any], updateType: TableViewUpdates, indexPaths: [IndexPath]?) {
        tableView.beginUpdates()
        switch updateType {
        case .insert:
            tableView.insertRows(at: indexPaths!, with: .middle)
            fallthrough
        case .reload:
            if let visibleIndexPaths = tableView.indexPathsForVisibleRows {
                tableView.reloadRows(at: visibleIndexPaths, with: .none)
            }
        case .delete:
            tableView.deleteRows(at: indexPaths!, with: .middle)
        }
        
        if let new = newDataSource as? [GCKDevice] {
            dataSource = new
        }
        
        tableView.endUpdates()
    }
    

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        if dataSource.isEmpty {
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
        return dataSource.isEmpty ? nil : "Google Cast"
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        
        cell.textLabel?.text = dataSource[indexPath.row].friendlyName
        cell.imageView?.image = UIImage(named: "CastOff")
        if let session = GCKCastContext.sharedInstance().sessionManager.currentSession {
            cell.accessoryType = dataSource[indexPath.row] == session.device ? .checkmark : .none
        } else {
            cell.accessoryType = .none
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        manager.didSelectDevice(dataSource[indexPath.row], castMetadata: castMetadata)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return dataSource.isEmpty ? .leastNormalMagnitude : 18
    }
    
    func didConnectToDevice() {
        //playerViewController.delegate?.presentCastPlayer(playerViewController.media, videoFilePath: playerViewController.directory, startPosition: TimeInterval(playerViewController.progressBar.progress))
    }
}
