

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
        didSet {
            
            originalText = text
            truncateAndUpdateText()
        }
    }
    
    private var textAttributes: [String : Any] {
        return [
            NSForegroundColorAttributeName: textColor!,
            NSFontAttributeName: font!
        ]
    }
    
    private var trailingTextAttributes: [String : Any] {
        return [
            NSForegroundColorAttributeName: trailingTextColor,
            NSFontAttributeName: font!
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
        selectGestureRecognizer.allowedTouchTypes = [NSNumber(value: UITouchType.direct.rawValue)]
        addGestureRecognizer(selectGestureRecognizer)
    }
    
    func expandView() {
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
