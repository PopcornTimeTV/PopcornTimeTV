

import Foundation
import TvOSMoreButton

class TVExpandableTextView: TvOSMoreButton {
    
    var isDark: Bool = true {
        didSet {
            let colorPallete: ColorPallete = isDark ? .light : .dark
            
            trailingTextColor = colorPallete.secondary
            textColor = colorPallete.primary
            
            blurStyle = isDark ? .dark : .extraLight
        }
    }
    
    var blurStyle: UIBlurEffect.Style = .dark {
        didSet {
            blurredView.effect = UIBlurEffect(style: blurStyle)
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        updateUI()
    }
    
    var blurredView: UIVisualEffectView {
        return recursiveSubviews.compactMap({$0 as? UIVisualEffectView}).first!
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
        isDark = true
        blurredView.contentView.backgroundColor = UIColor(white: 1.0, alpha: 0.2)
        font = .systemFont(ofSize: 30, weight: UIFont.Weight.medium)
        trailingTextFont = .boldSystemFont(ofSize: 25)
        focusedShadowOpacity = 0.5
        cornerRadius = 5
        focusedViewAlpha = 1
    }
    
    override func layoutIfNeeded() {
        if let label = recursiveSubviews.compactMap({$0 as? UILabel}).first {
            label.layoutIfNeeded()
        }
    }
}
