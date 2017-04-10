

import Foundation
import TvOSMoreButton

class TVExpandableTextView: TvOSMoreButton {
    
    override var focusedViewAlpha: CGFloat {
        get {
            return 1.0
        } set {}
    }
    
    override var cornerRadius: CGFloat {
        get {
            return 5
        } set {}
    }
    
    override var trailingTextColor: UIColor {
        get {
            return UIColor.white.withAlphaComponent(0.5)
        } set {}
    }
    
    override var focusedShadowOpacity: Float {
        get {
            return 0.5
        } set {}
    }
    
    var blurStyle: UIBlurEffectStyle = .dark {
        didSet {
            blurredView.effect = UIBlurEffect(style: blurStyle)
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        updateUI()
    }
    
    var blurredView: UIVisualEffectView {
        return recursiveSubviews.flatMap({$0 as? UIVisualEffectView}).first!
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        sharedSetup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        sharedSetup()
    }
    
    func sharedSetup() {
        blurredView.effect = UIBlurEffect(style: blurStyle)
        blurredView.contentView.backgroundColor = UIColor(white: 1.0, alpha: 0.2)
        font = .systemFont(ofSize: 30, weight: UIFontWeightMedium)
        trailingTextFont = .boldSystemFont(ofSize: 25)
    }
    
    override func layoutIfNeeded() {
        if let label = recursiveSubviews.flatMap({$0 as? UILabel}).first {
            label.layoutIfNeeded()
        }
    }
}
