

import Foundation

extension UITableView {
    
    @nonobjc var focusedCellIndexPath: IndexPath? {
        return value(forKey: "focusedCellIndexPath") as? IndexPath
    }
}
