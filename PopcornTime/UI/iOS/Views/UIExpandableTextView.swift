

import Foundation

@IBDesignable class UIExpandableTextView: UITextView {
    
    @IBInspectable var trailingText: String = "More".localized.localizedLowercase
    @IBInspectable var ellipsesString: String = "..."
    @IBInspectable var trailingTextColor: UIColor = .app
    
    @IBInspectable var maxHeight: CGFloat = 57
    
    private var originalText: String!
    private var _textColor: UIColor?
    
    override var textColor: UIColor? {
        get {
           return _textColor
        } set(color) {
            _textColor = color
        }
    }
    
    override var text: String! {
        get {
            return super.text
        } set {
            if ProcessInfo().operatingSystemVersion.majorVersion == 9 // System bug that doesn't respect `isSelectable` after changing the text. Fixed in iOS 10+.
            {
                let originalSelectableValue = isSelectable
                isSelectable = true
                super.text = newValue
                isSelectable = originalSelectableValue
            } else {
               super.text = newValue
            }
            
            originalText = text
            truncateAndUpdateText()
        }
    }
    
    private var textAttributes: [NSAttributedString.Key : Any] {
        return [
            NSAttributedString.Key.foregroundColor: textColor!,
            NSAttributedString.Key.font: font!
        ]
    }
    
    private var trailingTextAttributes: [NSAttributedString.Key : Any] {
        return [
            NSAttributedString.Key.foregroundColor: trailingTextColor,
            NSAttributedString.Key.font: font!
        ]
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        sharedSetup()
    }
    
    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        sharedSetup()
    }
    
    private func sharedSetup() {
        let selectGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(expandView))
        selectGestureRecognizer.allowedTouchTypes = [NSNumber(value: UITouch.TouchType.direct.rawValue)]
        addGestureRecognizer(selectGestureRecognizer)
    }
    
    @objc func expandView() {
        maxHeight = .greatestFiniteMagnitude
        untruncateAndUpdateText()
        
        superview?.setNeedsLayout()
        UIView.animate(withDuration: .default, animations: {
            self.superview?.layoutIfNeeded()
        }) { _ in
            self.superview?.parent?.viewDidLayoutSubviews()
        }
    }
    
    override var bounds: CGRect {
        didSet {
            guard oldValue != bounds else { return }
            
            truncateAndUpdateText()
        }
    }
    
    private func untruncateAndUpdateText() {
        attributedText = NSAttributedString(string: originalText, attributes: textAttributes)
    }
    
    private func truncateAndUpdateText() {
        guard let text = originalText, !text.isEmpty else { return }
        
        let trailingText = " " + self.trailingText
        attributedText = text.truncateToSize(size: CGSize(width: bounds.size.width, height: maxHeight),
                                                   ellipsesString: ellipsesString,
                                                   trailingText: trailingText,
                                                   attributes: textAttributes,
                                                   trailingTextAttributes: trailingTextAttributes)
    }
}
