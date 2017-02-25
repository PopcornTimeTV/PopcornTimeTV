

import Foundation

@IBDesignable class ExpandableTextView: UITextView {
    
    @IBInspectable var moreButtonText: String = "...more" {
        didSet {
            moreButton.setTitle(moreButtonText, for: .normal)
        }
    }
    
    @IBInspectable var maxHeight: CGFloat = 57 {
        didSet {
            heightConstraint.constant = maxHeight
        }
    }
    
    @IBInspectable var moreButtonBackgroundColor: UIColor? {
        didSet {
            moreButton.backgroundColor = moreButtonBackgroundColor
        }
    }
    
    override var font: UIFont? {
        didSet {
            moreButton.titleLabel?.font = font
        }
    }
    
    private var heightConstraint: NSLayoutConstraint!
    
    let moreButton = UIButton(type: .system)
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        sharedSetup()
    }
    
    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        sharedSetup()
    }
    
    private func sharedSetup() {
        moreButtonBackgroundColor = backgroundColor
        heightConstraint = NSLayoutConstraint(item: self, attribute: .height, relatedBy: .lessThanOrEqual, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: maxHeight)
        textContainer.maximumNumberOfLines = 0
        textContainer.lineBreakMode = .byWordWrapping
        moreButton.frame = CGRect(origin: CGPoint.zero, size: CGSize.max)
        moreButton.setTitle(moreButtonText, for: .normal)
        moreButton.sizeToFit()
        insertSubview(moreButton, aboveSubview: self)
        moreButton.addTarget(self, action: #selector(expandView), for: .touchUpInside)
        moreButton.isHidden = true
        addConstraint(heightConstraint)
    }
    
    func expandView() {
        heightConstraint.isActive = false
        superview?.setNeedsLayout()
        UIView.animate(withDuration: animationLength, animations: {
            self.superview?.layoutIfNeeded()
        }, completion: { _ in
            self.superview?.parent?.viewDidLayoutSubviews()
        })
    }
    
    
    var totalNumberOfLines: Int {
        let font = self.font ?? UIFont.systemFont(ofSize: 17)
        let maxSize = CGSize(width: frame.size.width, height: CGFloat.greatestFiniteMagnitude)
        let attributedText = NSAttributedString(string: text, attributes: [NSFontAttributeName: font])
        return Int(round(attributedText.boundingRect(with: maxSize, options: .usesLineFragmentOrigin, context: nil).size.height / font.lineHeight))
    }
    
    var visibleNumberOfLines: Int {
        return Int(round(contentSize.height) / (font ?? UIFont.systemFont(ofSize: 17)).lineHeight)
    }
    
    
    override func layoutSubviews() {
        super.layoutSubviews()
        moreButton.frame.origin.x = bounds.width - moreButton.frame.width - 5
        moreButton.frame.origin.y = bounds.height - moreButton.frame.height
        moreButton.isHidden = totalNumberOfLines <= visibleNumberOfLines
    }
}
