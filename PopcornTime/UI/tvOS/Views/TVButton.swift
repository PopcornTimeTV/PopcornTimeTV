

import Foundation

@IBDesignable class TVButton: UIControl {
    
    @IBOutlet var contentView: UIView?
    @IBOutlet var backgroundView: UIVisualEffectView?
    @IBOutlet var focusedView: UIView?
    @IBOutlet var imageView: UIImageView?
    @IBOutlet var titleLabel: UILabel?
    
    @IBInspectable private(set) var image: String? {
        didSet {
            if imageView == nil { loadViewIfNeeded() }
            if let named = image {
                setImage(UIImage(named: named), for: .normal)
            }
        }
    }
    
    @IBInspectable private(set) var title: String = "" {
        didSet {
            if titleLabel == nil { loadViewIfNeeded() }
            setTitle(title.localized, for: .normal)
        }
    }
    
    private var images: [UIControlState: UIImage?] = [:]
    private var titles: [UIControlState: String?]  = [:]
    
    private let pressAnimationDuration = 0.1
    private let shadowRadius: CGFloat = 10
    private let shadowColor: CGColor = UIColor.black.cgColor
    private let focusedShadowOffset = CGSize(width: 0, height: 27)
    private let focusedShadowOpacity: Float = 0.3
    
    var isDark = true {
        didSet {
            guard oldValue != isDark else { return }
            
            let colorPallete: ColorPallete = isDark ? .light : .dark
            titleLabel?.textColor = isFocused ? .white : colorPallete.secondary
            backgroundView?.contentView.backgroundColor = isDark ? .clear : colorPallete.tertiary
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        loadViewIfNeeded()
        
        self.layer.shadowColor = shadowColor
        self.layer.shadowRadius = shadowRadius
    }
    
    override func willMove(toWindow newWindow: UIWindow?) {
        super.willMove(toWindow: newWindow)
        if newWindow != nil {
            updateFocusedViewMask()
        }
    }
    
    private func updateImageView() {
        imageView?.image = images[state] ?? images[.normal] ?? nil
        updateFocusedViewMask()
    }
    
    private func updateTitleLabel() {
        titleLabel?.text = titles[state] ?? titles[.normal] ?? nil
    }
    
    func setImage(_ image: UIImage?, for state: UIControlState) {
        images[state] = image
        updateImageView()
    }
    
    func setTitle(_ title: String?, for state: UIControlState) {
        titles[state] = title
        updateTitleLabel()
    }
    
    func loadViewIfNeeded() {
        guard contentView == nil else { return }
        let _ = Bundle.main.loadNibNamed("TVButton", owner: self, options: nil)!.first
        addSubview(contentView!)
        contentView!.frame = bounds
    }
    
    override var canBecomeFocused: Bool {
        return isEnabled
    }
    
    override var intrinsicContentSize: CGSize {
        return CGSize(width: 142, height: 115)
    }
    
    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        coordinator.addCoordinatedAnimations({
            if context.nextFocusedView == self {
                self.applyFocusedAppearance()
            } else if context.previouslyFocusedView == self {
                self.applyUnfocusedAppearance()
            }
        })
    }
    
    // MARK: - Presses
    
    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        super.pressesBegan(presses, with: event)
        for item in presses where item.type == .select {
            applyPressDownAppearance()
            sendActions(for: .touchDown)
        }
    }
    
    override func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        super.pressesEnded(presses, with: event)
        for item in presses where item.type == .select {
            if isFocused {
                applyPressUpAppearance()
                sendActions(for: .primaryActionTriggered)
            } else {
                applyUnfocusedAppearance()
            }
        }
    }
    
    override func pressesCancelled(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        super.pressesCancelled(presses, with: event)
        for item in presses where item.type == .select {
            isFocused ? applyPressUpAppearance() : applyUnfocusedAppearance()
            sendActions(for: .touchCancel)
        }
    }
    
    // MARK: - Focus Appearance
    
    func applyFocusedAppearance() {
        transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
        layer.shadowOffset = focusedShadowOffset
        layer.shadowOpacity = focusedShadowOpacity
        focusedView?.isHidden = false
        titleLabel?.textColor = .white
        imageView?.isHidden = true
    }
    
    func applyUnfocusedAppearance() {
        transform = .identity
        layer.shadowOffset = .zero
        layer.shadowOpacity = 0
        focusedView?.isHidden = true
        titleLabel?.textColor = (isDark ? ColorPallete.light : ColorPallete.dark).secondary
        imageView?.isHidden = false
    }
    
    func applyPressUpAppearance() {
        UIView.animate(withDuration: pressAnimationDuration) {
            self.applyFocusedAppearance()
        }
    }
    
    func applyPressDownAppearance() {
        UIView.animate(withDuration: pressAnimationDuration) {
            self.transform = .identity
            self.layer.shadowOffset = .zero
            self.layer.shadowOpacity = 0
        }
    }
    
    func updateFocusedViewMask() {
        guard
            let contentView = backgroundView?.contentView,
            let focusedView = focusedView,
            let imageView = imageView
            else {
                return
        }
        
        let focusedHidden = focusedView.isHidden
        let imageHidden   = imageView.isHidden
        
        focusedView.isHidden = true
        imageView.isHidden = false
        
        let mask = UIGraphicsImageRenderer(bounds: contentView.bounds, format: .default()).image { context in
            contentView.layer.render(in: context.cgContext)
        }.scaled(to: focusedView.bounds.size).layerMask
        
        mask?.frame = focusedView.bounds
        focusedView.layer.mask = mask
        
        focusedView.isHidden = focusedHidden
        imageView.isHidden   = imageHidden
    }
    
    func invalidateAppearance() {
        updateFocusedViewMask()
    }
}
