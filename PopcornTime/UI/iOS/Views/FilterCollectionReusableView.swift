

import UIKit

class FilterCollectionReusableView: UICollectionReusableView {
    @IBOutlet var scrollView: UIScrollView?
    @IBOutlet var contentView: UIView?
    @IBOutlet var segmentedControl: UISegmentedControl?
    
    override func layoutSubviews() {
        super.layoutSubviews()
        scrollView?.layoutIfNeeded()
        scrollView?.contentSize = contentView!.bounds.size
    }
}
