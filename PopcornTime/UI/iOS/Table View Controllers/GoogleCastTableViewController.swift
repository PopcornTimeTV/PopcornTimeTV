

import UIKit
import GoogleCast
import PopcornKit

protocol GoogleCastTableViewControllerDelegate: class {
    func didConnectToDevice()
}

private enum TableViewUpdates {
    case reload
    case insert
    case delete
}

class GoogleCastTableViewController: UITableViewController, GCKDeviceScannerListener, GCKSessionManagerListener {
    
    var dataSource = [GCKDevice]()
    var connectionQueue: GCKDevice?
    
    private let deviceScanner = GCKDeviceScanner(filterCriteria: GCKFilterCriteria(forAvailableApplicationWithID: kGCKMediaDefaultReceiverApplicationID))
    private let sessionManager = GCKCastContext.sharedInstance().sessionManager
    
    weak var delegate: GoogleCastTableViewControllerDelegate?
    
    var sizingCell: UITableViewCell?
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        var estimatedHeight: CGFloat = 0
        
        for section in 0..<tableView.numberOfSections {
            
            estimatedHeight += tableView(tableView, heightForHeaderInSection: section)
            estimatedHeight += tableView(tableView, heightForFooterInSection: section)
            
            let rows = tableView.numberOfRows(inSection: section)
            
            for row in 0..<rows {
                estimatedHeight += tableView(tableView, heightForRowAt: IndexPath(row: row, section: section))
            }
        }
        
        estimatedHeight += tableView.contentInset.top
        
        preferredContentSize = CGSize(width: 320, height: estimatedHeight < 400 ? estimatedHeight : 400)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.contentInset.top = 20
        
        deviceScanner.add(self)
        deviceScanner.startScan()
        sessionManager.add(self)
    }
    
    @IBAction func cancel() {
        dismiss(animated: true)
    }
    
    private func update(tableView: UITableView, type: TableViewUpdates, rows: [Int]) {
        tableView.beginUpdates()
        
        let indexPaths: [IndexPath] = rows.compactMap({IndexPath(row: $0, section: 0)})
        
        switch type {
        case .insert:
            tableView.insertRows(at: indexPaths, with: .middle)
            fallthrough
        case .reload:
            if let visibleIndexPaths = tableView.indexPathsForVisibleRows {
                tableView.reloadRows(at: visibleIndexPaths, with: .none)
            }
        case .delete:
            tableView.deleteRows(at: indexPaths, with: .middle)
        }
        
        tableView.endUpdates()
    }
    
    func select(device: GCKDevice) {
        let connected = sessionManager.hasConnectedSession()
        
        if connected {
            sessionManager.endSession()
            connectionQueue = device
        } else {
            GCKCastContext.sharedInstance().sessionManager.startSession(with: device)
        }
    }
    
    // MARK: - GCKSessionManagerListener
    
    func sessionManager(_ sessionManager: GCKSessionManager, didEnd session: GCKSession, withError error: Error?) {
        if let device = connectionQueue {
            select(device: device)
        }
        tableView.reloadData()
    }
    
    func sessionManager(_ sessionManager: GCKSessionManager, didStart session: GCKSession) {
        if session.device == connectionQueue {
            connectionQueue = nil
        }
        delegate?.didConnectToDevice()
        tableView.reloadData()
    }
    
    // MARK: - GCKDeviceScannerListener
    
    public func deviceDidComeOnline(_ device: GCKDevice) {
        dataSource.append(device)
        update(tableView: tableView, type: .insert, rows: [dataSource.count - 1])
    }
    
    
    public func deviceDidGoOffline(_ device: GCKDevice) {
        for (index, oldDevice) in dataSource.enumerated() where device === oldDevice {
            dataSource.remove(at: index)
            update(tableView: tableView, type: .delete, rows: [index])
        }
    }
    
    public func deviceDidChange(_ device: GCKDevice) {
        for (index, oldDevice) in dataSource.enumerated() where device === oldDevice  {
            dataSource[index] = device
            update(tableView: tableView, type: .reload, rows: [index])
        }
    }
    

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        if dataSource.isEmpty {
            let label = UILabel(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
            label.text = "No devices available".localized
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
        return 1
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
        if let session = sessionManager.currentSession {
            cell.accessoryType = dataSource[indexPath.row] == session.device ? .checkmark : .none
        } else {
            cell.accessoryType = .none
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.cellForRow(at: indexPath)?.accessoryType = .none
        tableView.deselectRow(at: indexPath, animated: true)
        
        let device = dataSource[indexPath.row]
        
        // If the device is already connected to, the user wants to disconnect from said device.
        if sessionManager.currentSession?.device == device {
            sessionManager.endSession()
        } else {
            select(device: device)
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return dataSource.isEmpty ? .leastNormalMagnitude : 18
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        sizingCell = sizingCell ?? tableView.dequeueReusableCell(withIdentifier: "cell")
        
        sizingCell?.textLabel?.text = dataSource[indexPath.row].friendlyName
        
        sizingCell?.setNeedsLayout()
        sizingCell?.layoutIfNeeded()
        
        let maxWidth   = tableView.bounds.width
        let targetSize = CGSize(width: maxWidth, height: 0)
        
        return sizingCell?.contentView.systemLayoutSizeFitting(targetSize, withHorizontalFittingPriority: UILayoutPriority.required, verticalFittingPriority: UILayoutPriority.fittingSizeLevel).height ?? 44
    }
    
    deinit {
        if deviceScanner.scanning {
            deviceScanner.stopScan()
            deviceScanner.remove(self)
            GCKCastContext.sharedInstance().sessionManager.remove(self)
        }
    }
    
}
