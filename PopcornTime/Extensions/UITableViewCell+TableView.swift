

import Foundation

extension UITableViewCell {
    
    /// Locate the associated `UITableView` instance.
    weak var tableView: UITableView! {
        var superview = self.superview
        
        while !(superview is UITableView) {
            superview = superview?.superview
        }
        
        if let tableView = superview as? UITableView {
            return tableView
        }
        
        fatalError("Unexpected view hierarchy; UITableView not found.")
    }
}
