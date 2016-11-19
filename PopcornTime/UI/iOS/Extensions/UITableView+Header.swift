

import Foundation

extension UITableView {
    func sizeHeaderThatFits(_ size: CGSize) {
        guard let headerView = tableHeaderView else { return }
        headerView.frame.size = size
        tableHeaderView = headerView
        headerView.setNeedsLayout()
        headerView.layoutIfNeeded()
    }
}
