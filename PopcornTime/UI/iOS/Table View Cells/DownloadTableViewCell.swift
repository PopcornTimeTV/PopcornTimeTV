

import Foundation

class DownloadTableViewCell: UITableViewCell {
    
    @IBOutlet private var _textLabel: UILabel?
    @IBOutlet private var _detailTextLabel: UILabel?
    @IBOutlet private var _imageView: UIImageView?
    
    override var textLabel: UILabel? {
        return _textLabel
    }
    
    override var detailTextLabel: UILabel? {
        return _detailTextLabel
    }
    
    override var imageView: UIImageView? {
        return _imageView
    }
}
