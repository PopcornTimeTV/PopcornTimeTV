

import UIKit
import enum PopcornTorrent.PTTorrentDownloadStatus

class DownloadButton: BorderButton, UIGestureRecognizerDelegate {
    
    enum State {
        case downloading
        case paused
        case pending
        case normal
        case downloaded
        
        init(_ downloadStatus: PTTorrentDownloadStatus) {
            switch downloadStatus {
            case .downloading:
                self = .downloading
            case .paused:
                self = .paused
            case .processing:
                self = .pending
            case .finished:
                self = .downloaded
            case .failed:
                self = .normal
            }
        }
    }
    
    var downloadState: State = .normal {
        didSet {
            guard downloadState != oldValue else { return }
            
            invalidateAppearance()
        }
    }
    
    private var progressView = UIDownloadProgressView(endAngle: .pi * 1.5, lineWidth: 3)
    private var outlineView = UIDownloadProgressView()
    
    var progress: Float = 0 {
        didSet {
            progressView.endAngle = ((2 * CGFloat.pi) * CGFloat(progress)) + progressView.startAngle
        }
    }
    
    override var intrinsicContentSize: CGSize {
        guard downloadState != .normal, let imageView = imageView else {
            return super.intrinsicContentSize
        }
        let size = imageView.systemLayoutSizeFitting(UILayoutFittingCompressedSize)
        let common = Swift.max(size.width, size.height)
        
        return CGSize(width: common, height: common)
    }
    
    override func layoutIfNeeded() {
        super.layoutIfNeeded()
        
        outlineView.frame = bounds
        progressView.frame = bounds
    }
    
    private lazy var rotationAnimation: CABasicAnimation = {
        let rotation = CABasicAnimation(keyPath: "transform.rotation")
        rotation.fromValue = 0
        rotation.toValue = 2 * Double.pi
        rotation.duration = 1
        rotation.repeatCount = .infinity
        rotation.isRemovedOnCompletion = false
        return rotation
    }()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        [progressView, outlineView].forEach { [unowned self] in
            $0.isHidden = true
            self.addSubview($0)
        }
        
        clipsToBounds = false
        imageView?.contentMode = .center
        
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        gestureRecognizer.delegate = self
        addGestureRecognizer(gestureRecognizer)
    }
    
    @objc private func handleLongPress(_ longPressGesture: UILongPressGestureRecognizer) {
        guard downloadState != .normal, longPressGesture.state == .began else { return }
        
        sendActions(for: .applicationReserved)
    }
    
    override func invalidateAppearance() {
        defer {
            setNeedsLayout()
            layoutIfNeeded()
            invalidateIntrinsicContentSize()
        }
        
        if downloadState != .pending, imageView?.layer.animation(forKey: "Spin") != nil {
            imageView?.layer.removeAnimation(forKey: "Spin")
        }
        
        if downloadState != .normal {
            setTitle(nil, for: .normal)
            layer.borderWidth = 0
            backgroundColor = .clear
        }
        
        switch downloadState {
        case .downloaded:
            setImage(UIImage(named: "Download Progress Finished"), for: .normal)
            [progressView, outlineView].forEach { $0.isHidden = true }
        case .normal:
            super.invalidateAppearance()
            setImage(nil, for: .normal)
            layer.borderWidth = borderWidth
            setTitle(titleLabel?.text, for: .normal)
            [progressView, outlineView].forEach { $0.isHidden = true }
        case .downloading:
            setImage(UIImage(named: "Download Progress Pause"), for: .normal)
            [progressView, outlineView].forEach { $0.isHidden = false }
        case .paused:
            setImage(UIImage(named: "Download Progress Resume"), for: .normal)
            [progressView, outlineView].forEach { $0.isHidden = false }
        case .pending:
            let image = UIImage(named: "Download Progress Indeterminate")
            imageView?.image != image ? setImage(image, for: .normal) : ()
            imageView?.layer.animation(forKey: "Spin") == nil ? imageView?.layer.add(rotationAnimation, forKey: "Spin") : ()
            [progressView, outlineView].forEach { $0.isHidden = true }
        }
    }
}
