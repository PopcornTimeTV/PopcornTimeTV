

import Foundation

enum TransportBarHint: String {
    case none
    case fastForward = "ScanForward"
    case rewind = "ScanBackward"
    case jumpForward30 = "SkipForward30"
    case jumpBackward30 = "SkipBack30"
}

@IBDesignable class ProgressBar: UIView {
    
    @IBInspectable var progress: Float = 0.0 {
        didSet {
            if progress < 0.0 { progress = 0.0 }
            if progress > 1.0 { progress = 1.0 }
            
            scrubbingTimeLabel.text = elapsedTimeLabel.text
            scrubbingProgress = progress
            
            if !isScrubbing { bufferingBar.elapsedProgress = progress }
            
            setNeedsLayout()
            layoutIfNeeded()
        }
    }
    
    @IBInspectable var scrubbingProgress: Float = 0.0 {
        didSet {
            if scrubbingProgress < 0.0 { scrubbingProgress = 0.0 }
            if scrubbingProgress > 1.0 { scrubbingProgress = 1.0 }
            setNeedsLayout()
            layoutIfNeeded()
        }
    }
    @IBInspectable var bufferProgress: Float = 0.0 {
        didSet {
            bufferingBar.bufferProgress = bufferProgress
            setNeedsLayout()
            layoutIfNeeded()
        }
    }
    
    @IBInspectable var screenshot: UIImage? {
        didSet {
            screenshotImageView.image = screenshot
            
            let color: UIColor = isImageHidden ? .clear : .black
            screenshotImageView.backgroundColor = color
            screenshotImageView.layer.borderWidth = isImageHidden ? 0.0 : 1.0
            
            setNeedsLayout()
            UIView.animate(withDuration: 0.3) {
                self.layoutIfNeeded()
            }
        }
    }
    @IBInspectable var isScrubbing: Bool = false {
        didSet {
            if isScrubbing {
                scrubbingProgress = progress
                scrubbingPositionMarker.isHidden = false
                elapsedTimeLabel.textColor = .darkGray
                remainingTimeLabel.textColor = .darkGray
                playbackPositionMarker.alpha = 0.6
                
                var frame = screenshotImageView.frame
                frame.origin.y = scrubbingPositionMarker.frame.origin.y
                frame.size = .zero
                screenshotImageView.alpha = 0.0
                screenshotImageView.isHidden = false
                
                screenshotImageView.frame = frame
                
                frame.size = CGSize(width: 480, height: 270)
                frame.origin.y = scrubbingPositionMarker.frame.origin.y - frame.size.height
                
                UIView.animate(withDuration: 0.3, animations: { 
                    self.screenshotImageView.frame = frame
                    self.screenshotImageView.alpha = 1.0
                    self.layoutIfNeeded()
                })
            } else {
                playbackPositionMarker.alpha = 1.0
                elapsedTimeLabel.textColor = .white
                remainingTimeLabel.textColor = .white
                scrubbingPositionMarker.isHidden = true
                
                var frame = screenshotImageView.frame
                frame.origin.y = scrubbingPositionMarker.frame.origin.y
                frame.size = .zero
                
                UIView.animate(withDuration: 0.3, animations: { 
                    self.screenshotImageView.frame = frame
                    self.screenshotImageView.alpha = 0.0
                    self.layoutIfNeeded()
                }, completion: { _ in
                    self.screenshotImageView.isHidden = true
                    self.screenshotImageView.image = nil
                })
            }
            setNeedsLayout()
        }
    }
    
    @IBInspectable var isBuffering: Bool = false {
        didSet {
            bufferingIndicatorView.isHidden = !isBuffering
            rightHintImageView.isHidden = isBuffering
            leftHintImageView.isHidden = isBuffering
            
            setNeedsLayout()
            layoutIfNeeded()
        }
    }
    
    let elapsedTimeLabel = UILabel()
    let remainingTimeLabel = UILabel()
    let scrubbingTimeLabel = UILabel()
    
    var hint: TransportBarHint = .none {
        didSet {
            var leftImage: UIImage?
            var rightImage: UIImage?
            
            switch hint {
            case _ where hint == .fastForward || hint == .jumpForward30:
                rightImage = UIImage(named: hint.rawValue)?.withRenderingMode(.alwaysTemplate)
            case _ where hint == .jumpBackward30 || hint == .rewind:
                leftImage = UIImage(named: hint.rawValue)?.withRenderingMode(.alwaysTemplate)
            default: break
            }
            
            leftHintImageView.image = leftImage
            rightHintImageView.image = rightImage
        }
    }
    
    let bufferingBar = BufferingBar()
    
    private let playbackPositionMarker = UIView()
    private let scrubbingPositionMarker = UIView()
    private let bufferingIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: .white)
    
    private let leftHintImageView = UIImageView()
    private let rightHintImageView = UIImageView()
    private let screenshotImageView = UIImageView()
    
    private var isImageHidden: Bool {
        return screenshot == nil
    }
    
    private let markerWidth: CGFloat = 2.0
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        sharedSetup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        sharedSetup()
    }
    
    func sharedSetup() {
        bufferingBar.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        bufferingBar.bufferProgress = bufferProgress
        bufferingBar.frame = bounds

        screenshotImageView.clipsToBounds = true
        screenshotImageView.layer.borderColor = UIColor(white: 1.0, alpha: 0.2).cgColor
        screenshotImageView.contentMode = .scaleAspectFit
        screenshotImageView.frame = CGRect(origin: .zero, size: CGSize(width: 480, height: 270))
        
        let size = UIFont.preferredFont(forTextStyle: .callout).pointSize
        let font = UIFont.monospacedDigitSystemFont(ofSize: size, weight: UIFontWeightSemibold)
        let text = "--:--"
        let color = UIColor.white
        let frame = CGRect.infinite
        
        elapsedTimeLabel.font = font
        elapsedTimeLabel.text = text
        elapsedTimeLabel.textColor = color
        elapsedTimeLabel.frame = frame
        
        remainingTimeLabel.font = font
        remainingTimeLabel.text = text
        remainingTimeLabel.textColor = color
        remainingTimeLabel.frame = frame
        
        let origin = CGPoint(x: screenshotImageView.bounds.origin.x + (screenshotImageView.bounds.size.width/2) - 40, y: screenshotImageView.bounds.size.height - 50)
        scrubbingTimeLabel.frame = CGRect(origin: origin, size: CGSize(width: 10, height: 10))
        
        scrubbingTimeLabel.font = font
        scrubbingTimeLabel.text = text
        scrubbingTimeLabel.textColor = color
        
        scrubbingPositionMarker.backgroundColor = .white
        scrubbingPositionMarker.isHidden = true
        
        playbackPositionMarker.backgroundColor = .white
        
        bufferingIndicatorView.startAnimating()
        bufferingIndicatorView.isHidden = true
        
        let imageFrame = CGRect(origin: .zero, size: CGSize(width: 40, height: 40))
        
        leftHintImageView.frame = imageFrame
        leftHintImageView.contentMode = .center
        leftHintImageView.tintColor = .white
        
        rightHintImageView.frame = imageFrame
        rightHintImageView.contentMode = .center
        rightHintImageView.tintColor = .white
        
        addSubview(bufferingBar)
        addSubview(screenshotImageView)
        addSubview(elapsedTimeLabel)
        addSubview(remainingTimeLabel)
        addSubview(scrubbingPositionMarker)
        addSubview(playbackPositionMarker)
        addSubview(bufferingIndicatorView)
        addSubview(leftHintImageView)
        addSubview(rightHintImageView)
        screenshotImageView.addSubview(scrubbingTimeLabel)
    }
    
    override func layoutIfNeeded() {
        super.layoutIfNeeded()
        
        let width = bounds.width - markerWidth
        
        let progressFrame = progressMarkerFrame(forBounds: bounds, progressFraction: progress)
        let scrubberFrame = scrubbingMarkerFrame(forBounds: bounds, scrubFraction: scrubbingProgress)
        
        
        scrubbingPositionMarker.frame = scrubberFrame
        playbackPositionMarker.frame = progressFrame
        
        var screenshotFrame = screenshotImageView.frame
        screenshotFrame.origin.x = scrubberFrame.origin.x - screenshotFrame.size.width/2
        
        // Make sure image view is not off the screen.
        if screenshotFrame.origin.x < bounds.origin.x && !isImageHidden { screenshotFrame.origin.x = bounds.origin.x }
        if screenshotFrame.maxX > bounds.maxX && !isImageHidden { screenshotFrame.origin.x = bounds.maxX - screenshotFrame.size.width }
        
        screenshotImageView.frame = screenshotFrame
        
        
        remainingTimeLabel.sizeToFit()
        remainingTimeLabel.frame.origin.y = bounds.maxY + 15.0
        remainingTimeLabel.frame.origin.x = width - remainingTimeLabel.frame.width
        
        elapsedTimeLabel.sizeToFit()
        
        scrubbingTimeLabel.isHidden = scrubbingTimeLabel.text == elapsedTimeLabel.text
        scrubbingTimeLabel.sizeToFit()
        
        var timeLabelCenter = remainingTimeLabel.center
        timeLabelCenter.x = playbackPositionMarker.center.x
        elapsedTimeLabel.center = timeLabelCenter

        let indicatorWidth = bufferingIndicatorView.bounds.width
        bufferingIndicatorView.center = CGPoint(x: elapsedTimeLabel.frame.maxX + indicatorWidth, y: timeLabelCenter.y)
        
        let leftImageWidth = leftHintImageView.bounds.width
        leftHintImageView.center = CGPoint(x: elapsedTimeLabel.frame.minX - leftImageWidth, y: timeLabelCenter.y)
        
        let rightImageWidth = rightHintImageView.bounds.width
        rightHintImageView.center = CGPoint(x: elapsedTimeLabel.frame.maxX + rightImageWidth, y: timeLabelCenter.y)
        
        let timeLabelIntersects = elapsedTimeLabel.frame.intersects(remainingTimeLabel.frame)
        
        let imageViewIntersects = rightHintImageView.frame.intersects(remainingTimeLabel.frame) && rightHintImageView.image != nil
        
        let bufferIndicatorIntersects = bufferingIndicatorView.frame.intersects(remainingTimeLabel.frame) && bufferingIndicatorView.isHidden == false
        
        let shouldHideRemainingTime = timeLabelIntersects || imageViewIntersects || bufferIndicatorIntersects
        let alpha: CGFloat = shouldHideRemainingTime ? 0.0 : 1.0
        
        UIView.animate(withDuration: 0.15) {
            self.remainingTimeLabel.alpha = alpha
        }
    }
    
    
    func scrubbingMarkerFrame(forBounds bounds: CGRect, scrubFraction fraction: Float) -> CGRect {
        let width = bounds.width - markerWidth
        let height = bounds.height
    
        let scrubbingHeight = height * 3.0
        
        // x position is always center of marker == view width * fraction
        let scrubbingXPosition = width * CGFloat(fraction)
        let scrubbingYPosition = height - scrubbingHeight
        
        return CGRect(x: scrubbingXPosition, y: scrubbingYPosition, width: markerWidth, height: scrubbingHeight)
    }
    
    func progressMarkerFrame(forBounds bounds: CGRect, progressFraction fraction: Float) -> CGRect {
        let width = bounds.width - markerWidth
        let height = bounds.height
        
        // x position is always center of marker == view width * fraction
        let scrubbingXPosition = width * CGFloat(fraction)
        
        return CGRect(x: scrubbingXPosition, y: 0, width: markerWidth, height: height)
    }
}
