

import Foundation

protocol DownloadDetailTableViewCellDelegate: class {
    func cell(_ cell: DownloadDetailTableViewCell, accessoryButtonPressed button: DownloadButton)
    func cell(_ cell: DownloadDetailTableViewCell, longPressDetected gesture: UILongPressGestureRecognizer)
}

extension DownloadDetailTableViewCellDelegate {
    func cell(_ cell: DownloadDetailTableViewCell, longPressDetected gesture: UILongPressGestureRecognizer) {}
}

class DownloadDetailTableViewCell: DownloadTableViewCell {
    
    @IBOutlet var downloadButton: DownloadButton!
    
    weak var delegate: DownloadDetailTableViewCellDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        downloadButton.addTarget(self, action: #selector(longPressDetected(_:)), for: .applicationReserved)
    }
    
    @IBAction func accessoryButtonPressed(_ sender: DownloadButton) {
        delegate?.cell(self, accessoryButtonPressed: sender)
    }
    
    @objc func longPressDetected(_ gesture: UILongPressGestureRecognizer) {
        guard downloadButton.downloadState != .downloaded && gesture.state == .began else { return }
        delegate?.cell(self, longPressDetected: gesture)
    }
}
