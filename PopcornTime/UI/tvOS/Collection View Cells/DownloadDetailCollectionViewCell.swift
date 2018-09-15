

import Foundation
import class PopcornTorrent.PTTorrentDownload
import MediaPlayer.MPMediaItem

protocol DownloadCollectionViewCellDelegate: class {
    func cell(_ cell: DownloadCollectionViewCell, longPressDetected gesture: UILongPressGestureRecognizer)
}

class DownloadCollectionViewCell: BaseCollectionViewCell {
    
    @IBOutlet var blurView: UIVisualEffectView!
    @IBOutlet var progressView: UIDownloadProgressView!
    @IBOutlet var pausedImageView: UIImageView!
    
    
    var downloadState: DownloadButton.Status = .normal {
        didSet {
            guard downloadState != oldValue else { return }
            
            invalidateAppearance()
        }
    }
    
    var progress: Float = 0 {
        didSet {
            progressView.endAngle = ((2 * CGFloat.pi) * CGFloat(progress)) + progressView.startAngle
        }
    }
    
    weak var delegate: DownloadCollectionViewCellDelegate?
    
    @objc func longPressDetected(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began else { return }
        delegate?.cell(self, longPressDetected: gesture)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        let gesture = UILongPressGestureRecognizer(target: self, action: #selector(longPressDetected(_:)))
        addGestureRecognizer(gesture)
        
        focusedConstraints.append(blurView.heightAnchor.constraint(equalTo: imageView.focusedFrameGuide.heightAnchor))
        focusedConstraints.append(blurView.widthAnchor.constraint(equalTo: imageView.focusedFrameGuide.widthAnchor))
        
        progressView.endAngle = .pi * 1.5
    }
    
    func invalidateAppearance() {
        pausedImageView.isHidden = downloadState != .paused
        progressView.isFilled = downloadState != .paused
        blurView.isHidden = downloadState == .downloaded
    }
    
}

extension DownloadCollectionViewCell: CellCustomizing {

    func configureCellWith<T>(_ item: T) {

        guard let download = item as? PTTorrentDownload else { print(">>> initializing cell with invalid item"); return }

        self.progress = download.torrentStatus.totalProgress
        self.downloadState = DownloadButton.Status(download.downloadStatus)

        if let image = download.mediaMetadata[MPMediaItemPropertyArtwork] as? String, let url = URL(string: image) {
            self.imageView?.af_setImage(withURL: url)
        } else {
            self.imageView?.image = UIImage(named: "Episode Placeholder")
        }

        self.titleLabel?.text = download.mediaMetadata[MPMediaItemPropertyTitle] as? String
        self.blurView.isHidden = download.downloadStatus == .finished
    }
}
