

import Foundation

protocol DownloadTableViewCellDelegate: class {
    func cell(_ cell: DownloadTableViewCell, accessoryButtonPressed button: DownloadButton)
    func cell(_ cell: DownloadTableViewCell, longPressDetected gesture: UILongPressGestureRecognizer)
}

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
    
    @IBOutlet var downloadButton: DownloadButton!
    
    weak var delegate: DownloadTableViewCellDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        downloadButton.addTarget(self, action: #selector(longPressDetected(_:)), for: .applicationReserved)
    }
    
    @IBAction func accessoryButtonPressed(_ sender: DownloadButton) {
        delegate?.cell(self, accessoryButtonPressed: sender)
    }
    
    func longPressDetected(_ gesture: UILongPressGestureRecognizer) {
        guard downloadButton.downloadState != .downloaded else { return }
        delegate?.cell(self, longPressDetected: gesture)
    }

}
