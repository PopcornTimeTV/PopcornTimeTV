

import UIKit
import enum PopcornTorrent.PTTorrentDownloadStatus

#if os(iOS)
    typealias UIDownloadButton = BorderButton
#elseif os(tvOS)
    typealias UIDownloadButton = TVButton
#endif
    
class DownloadButton: UIDownloadButton, UIGestureRecognizerDelegate {
    
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
    
    private var progressView = UIDownloadProgressView(endAngle: .pi * 1.5, lineWidth: UIDevice.current.userInterfaceIdiom == .tv ? 10 : 3, isFilled: UIDevice.current.userInterfaceIdiom == .tv)
    private var outlineView = UIDownloadProgressView(lineWidth: UIDevice.current.userInterfaceIdiom == .tv ? 5 : 1)
    
    var progress: Float = 0 {
        didSet {
            guard progress != oldValue else { return }
            
            progressView.endAngle = ((2 * CGFloat.pi) * CGFloat(progress)) + progressView.startAngle
            
            #if os(tvOS)
                isFocused ? updateFocusedViewMask() : () // Because this call is very expensive and the mask is automatically updated upon focus, the only time we need to actively update the mask for the user to see the progress is when the button is focused.
            #endif
        }
    }
    
    private var rotationAnimation: CABasicAnimation {
        let rotation = CABasicAnimation(keyPath: "transform.rotation")
        rotation.fromValue = 0
        rotation.toValue = 2 * Double.pi
        rotation.duration = 1
        rotation.repeatCount = .infinity
        rotation.isRemovedOnCompletion = false
        return rotation
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        #if os(tvOS)
            let bounds = backgroundView?.contentView.bounds ?? self.bounds
        #endif
        
        let image  = UIImageView(image: UIImage(named: "Download Progress Indeterminate"))
        let size   = image.systemLayoutSizeFitting(UILayoutFittingCompressedSize)
        let center = CGPoint(x: bounds.width/2, y: bounds.height/2)
        let origin = CGPoint(x: center.x - size.width/2, y: center.y - size.height/2)
        let frame  = CGRect(origin: origin, size: size)
        
        outlineView.frame  = frame
        progressView.frame = frame
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        [progressView, outlineView].forEach { [unowned self] in
            $0.isHidden = true
            #if os(tvOS)
                let view = self.backgroundView!.contentView
            #elseif os(iOS)
                let view = self
            #endif
            view.addSubview($0)
        }
        
        clipsToBounds = false
        imageView?.contentMode = .center
        
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        gestureRecognizer.delegate = self
        addGestureRecognizer(gestureRecognizer)
    }
    
    @objc private func handleLongPress(_ longPressGesture: UILongPressGestureRecognizer) {
        guard (downloadState != .normal || downloadState != .downloaded) && longPressGesture.state == .began else { return }
        
        sendActions(for: .applicationReserved)
    }
    
    override var intrinsicContentSize: CGSize {
        guard downloadState != .normal, let imageView = imageView, UIDevice.current.userInterfaceIdiom != .tv else {
            return super.intrinsicContentSize
        }
        let size = imageView.systemLayoutSizeFitting(UILayoutFittingCompressedSize)
        let common = Swift.max(size.width, size.height)
        
        return CGSize(width: common, height: common)
    }
    
    #if os(tvOS)
    
    override func applyFocusedAppearance() {
        [progressView, outlineView].forEach { $0.isHidden = true }
        downloadState == .downloading ? updateFocusedViewMask() : () // Because this call is very expensive and the mask only changes when progress changes, - and when `downloadState` changes, but that is already handled in the didSet method - it is only called while downloading.
        super.applyFocusedAppearance()
    }
    
    override func applyUnfocusedAppearance() {
        [progressView, outlineView].forEach {
            $0.isHidden = !(self.downloadState == .downloading || self.downloadState == .paused)
        }
        super.applyUnfocusedAppearance()
    }
    
    override func updateFocusedViewMask() {
        let downloadProgressViewsHidden = outlineView.isHidden
        
        [progressView, outlineView].forEach { $0.isHidden = !(self.downloadState == .downloading || self.downloadState == .paused)  }
        
        super.updateFocusedViewMask()
        
        [progressView, outlineView].forEach { $0.isHidden = downloadProgressViewsHidden }
    }
    
    #endif
    
    override func invalidateAppearance() {
        defer {
            #if os(tvOS)
                updateFocusedViewMask()
            #endif
            setNeedsLayout()
            UIView.animate(withDuration: .default) { [unowned self] in
                self.layoutIfNeeded()
                self.invalidateIntrinsicContentSize()
            }
        }
        
        var layers = [imageView?.layer]
        #if os(tvOS)
            layers.append(focusedView?.layer)
        #endif
        
        layers.flatMap({$0}).forEach {
            if downloadState != .pending && $0.animation(forKey: "Spin") != nil {
                $0.removeAnimation(forKey: "Spin")
            }
        }
        
        if downloadState != .normal && UIDevice.current.userInterfaceIdiom != .tv {
            setTitle(nil, for: .normal)
            layer.borderWidth = 0
            backgroundColor = .clear
        }
        
        switch downloadState {
        case .downloaded:
            setImage(UIImage(named: "Download Progress Finished"), for: .normal)
            UIDevice.current.userInterfaceIdiom == .tv ? setTitle("Options".localized, for: .normal) : ()
            [progressView, outlineView].forEach { $0.isHidden = true }
        case .normal:
            #if os(iOS)
                super.invalidateAppearance()
                setImage(nil, for: .normal)
                layer.borderWidth = borderWidth
                setTitle(titleLabel?.text, for: .normal)
            #elseif os(tvOS)
                setImage(UIImage(named: "Download Progress Start"), for: .normal)
                setTitle(title, for: .normal)
            #endif
            [progressView, outlineView].forEach { $0.isHidden = true }
        case .downloading:
            if UIDevice.current.userInterfaceIdiom == .tv {
                setTitle("Downloading".localized, for: .normal)
                setImage(nil, for: .normal)
                progressView.isFilled = true
            } else {
               setImage(UIImage(named: "Download Progress Pause"), for: .normal)
            }
            [progressView, outlineView].forEach { $0.isHidden = self.isFocused }
        case .paused:
            if UIDevice.current.userInterfaceIdiom == .tv {
                setTitle("Paused".localized, for: .normal)
                setImage(UIImage(named: "Download Progress Pause"), for: .normal)
                progressView.isFilled = false
            } else {
                setImage(UIImage(named: "Download Progress Resume"), for: .normal)
            }
            [progressView, outlineView].forEach { $0.isHidden = self.isFocused }
        case .pending:
            let image = UIImage(named: "Download Progress Indeterminate")
            imageView?.image != image ? setImage(image, for: .normal) : ()
            
            layers.flatMap({$0}).forEach {
                if $0.animation(forKey: "Spin") == nil {
                    $0.add(self.rotationAnimation, forKey: "Spin")
                }
            }
            
            UIDevice.current.userInterfaceIdiom == .tv ? setTitle("Pending".localized, for: .normal) : ()
            [progressView, outlineView].forEach { $0.isHidden = true }
        }
    }
}
