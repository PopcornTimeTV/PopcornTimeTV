

import UIKit
import GoogleCast
import PopcornKit

protocol GoogleCastTableViewControllerDelegate: class {
    func didConnectToDevice()
}

class GoogleCastTableViewController: UITableViewController, GCKDeviceScannerListener, GoogleCastManagerDelegate {
    
    var dataSource = [GCKDevice]()
    var manager = GoogleCastManager()
    var castMetadata: CastMetaData?
    
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
        manager.delegate = self
    }
    
    @IBAction func cancel() {
        dismiss(animated: true)
    }
    
    func updateTableView(dataSource newDataSource: [GCKDevice], updateType: TableViewUpdates, rows: [Int]?) {
        tableView.beginUpdates()
        
        let indexPaths: [IndexPath]? = rows?.flatMap({IndexPath(row: $0, section: 0)})
        
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
        
        dataSource = newDataSource
        
        tableView.endUpdates()
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
        if let session = GCKCastContext.sharedInstance().sessionManager.currentSession {
            cell.accessoryType = dataSource[indexPath.row] == session.device ? .checkmark : .none
        } else {
            cell.accessoryType = .none
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.cellForRow(at: indexPath)?.accessoryType = .none
        manager.didSelectDevice(dataSource[indexPath.row], castMetadata: castMetadata)
        tableView.deselectRow(at: indexPath, animated: true)
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
        
        return sizingCell?.contentView.systemLayoutSizeFitting(targetSize, withHorizontalFittingPriority: UILayoutPriorityRequired, verticalFittingPriority: UILayoutPriorityFittingSizeLevel).height ?? 44
    }
    
    func didConnectToDevice() {
        tableView.reloadData()
        
        delegate?.didConnectToDevice()
    }
}
