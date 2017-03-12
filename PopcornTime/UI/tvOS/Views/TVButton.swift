

import Foundation

@IBDesignable class TVButton: UIControl {
    
    @IBOutlet var contentView: UIView!
    @IBOutlet var backgroundView: UIVisualEffectView!
    @IBOutlet var focusedView: UIView!
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var titleLabel: UILabel!
    
    @IBInspectable var image: String? {
        didSet {
            if imageView == nil { loadView() }
            if let named = image {
                imageView.image = UIImage(named: named)
            }
        }
    }
    
    @IBInspectable var title: String? {
        didSet {
            if titleLabel == nil { loadView() }
            if let text = title {
                titleLabel.text = text
            }
        }
    }
    
    private let pressAnimationDuration = 0.1
    private let shadowRadius: CGFloat = 10
    private let shadowColor:  CGColor = UIColor.black.cgColor
    private let focusedShadowOffset = CGSize(width: 0, height: 27)
    private let focusedShadowOpacity: Float = 0.3
    
    private var classContext = 0
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        loadView()
        
        self.layer.shadowColor = shadowColor
        self.layer.shadowRadius = shadowRadius
        
        let selectGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(selectGestureWasPressed))
        selectGestureRecognizer.allowedPressTypes = [NSNumber(value: UIPressType.select.rawValue)]
        addGestureRecognizer(selectGestureRecognizer)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if let keyPath = keyPath, keyPath == "image", context == &classContext {
            if let copy = imageView.image?.copy() as? UIImage,
                let image = copy.colored(.black)?.scaled(to: backgroundView.bounds.size).removingTransparency(), // Image has to be a black image on a white background for mask to work.
                let ciImage = CIImage(image: image),
                let filter = CIFilter(name:"CIMaskToAlpha") {
                filter.setValue(ciImage, forKey: "inputImage")
                let out = filter.outputImage!
                let image = CIContext().createCGImage(out, from: out.extent)
                let layer = CALayer()
                layer.frame = focusedView.frame
                layer.contents = image
                layer.contentsGravity = kCAGravityCenter
                focusedView.layer.mask = layer
            }
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
    
    func loadView() {
        guard contentView == nil else { return }
        
        let _ = Bundle.main.loadNibNamed(String(describing: type(of: self)), owner: self, options: nil)?.first
        addSubview(contentView)
        contentView.frame = bounds
        imageView.addObserver(self, forKeyPath: "image", options: .new, context: &classContext)
    }
    
    override var canBecomeFocused: Bool {
        return true
    }
    
    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        coordinator.addCoordinatedAnimations({
            self.isFocused ? self.applyFocusedAppearance() : self.applyUnfocusedAppearance()
        })
    }
    
    // MARK: - Presses
    
    override open func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        super.pressesBegan(presses, with: event)
        for item in presses where item.type == .select {
            applyPressDownAppearance()
        }
    }
    
    override open func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        super.pressesEnded(presses, with: event)
        for item in presses where item.type == .select {
            applyPressUpAppearance()
        }
    }
    
    override open func pressesCancelled(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        for item in presses where item.type == .select {
            applyPressUpAppearance()
        }
    }
    
    @objc private func selectGestureWasPressed() {
        sendActions(for: .primaryActionTriggered)
    }
    
    // MARK: - Focus Appearance
    
    private func applyFocusedAppearance() {
        transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
        layer.shadowOffset = focusedShadowOffset
        layer.shadowOpacity = focusedShadowOpacity
        focusedView.isHidden = false
        titleLabel.textColor = .white
        imageView.isHidden = true
    }
    
    private func applyUnfocusedAppearance() {
        transform = .identity
        layer.shadowOffset = .zero
        layer.shadowOpacity = 0
        focusedView.isHidden = true
        titleLabel.textColor = UIColor(white: 1.0, alpha: 0.6)
        imageView.isHidden = false
    }
    
    private func applyPressUpAppearance() {
        UIView.animate(withDuration: pressAnimationDuration, animations: {
            self.applyFocusedAppearance()
        })
    }
    
    private func applyPressDownAppearance() {
        UIView.animate(withDuration: pressAnimationDuration, animations: {
            self.transform = .identity
            self.layer.shadowOffset = .zero
            self.layer.shadowOpacity = 0
        })
    }
    
    deinit {
        do { try imageView.remove(self, for: "image", in: &classContext) } catch {}
    }
}
