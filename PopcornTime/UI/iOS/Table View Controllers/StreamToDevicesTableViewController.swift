

import Foundation

class StreamToDevicesTableViewController: GoogleCastTableViewController {
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return section == 1 ? "AirPlay" : super.tableView(tableView, titleForHeaderInSection: section)
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 1 ? 1 : super.tableView(tableView, numberOfRowsInSection: section)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 1 {
            tableView.deselectRow(at: indexPath, animated: true)
            (tableView.cellForRow(at: indexPath) as! AirPlayTableViewCell).routeButton.sendActions(for: .touchUpInside)
        } else {
            super.tableView(tableView, didSelectRowAt: indexPath)
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 1 {
            return tableView.dequeueReusableCell(withIdentifier: "airPlayCell", for: indexPath)
        } else {
            return super.tableView(tableView, cellForRowAt: indexPath)
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return section == 1 ? 18 : super.tableView(tableView, heightForHeaderInSection: section)
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return indexPath.section == 1 ? 44 : super.tableView(tableView, heightForRowAt: indexPath)
    }
}
