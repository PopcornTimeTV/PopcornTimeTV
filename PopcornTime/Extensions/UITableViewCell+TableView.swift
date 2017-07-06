

import Foundation

extension UITableViewCell {
    
    /// The cell's table view.
    weak var tableView: UITableView? {
        var superview = self.superview
        
        while superview != nil && !(superview is UITableView) {
            superview = superview?.superview
        }
        
        return superview as? UITableView
    }
}
