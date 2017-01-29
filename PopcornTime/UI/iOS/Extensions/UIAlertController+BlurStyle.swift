

import Foundation

extension UIAlertController {
    
    private struct AssociatedKeys {
        static var blurStyleKey = "UIAlertController.blurStyleKey"
    }
    
    #if os(iOS)
    
    @nonobjc public var preferredAction: UIAlertAction? {
        get {
            return perform(Selector("preferredAction"))?.takeUnretainedValue() as? UIAlertAction
        } set (action) {
            perform(Selector("setPreferredAction:"), with: action)
            actions.forEach({$0.isChecked = false})
            action?.isChecked = true
        }
    }
    
    open override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        visualEffectView?.effect = UIBlurEffect(style: blurStyle)
        cancelActionView?.backgroundColor = cancelButtonColor
        preferredAction?.isChecked = true
    }
    
    #endif
    
    public var blurStyle: UIBlurEffectStyle {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.blurStyleKey) as? UIBlurEffectStyle ?? .extraLight
        } set (style) {
            objc_setAssociatedObject(self, &AssociatedKeys.blurStyleKey, style, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            
            view.setNeedsLayout()
            view.layoutIfNeeded()
        }
    }
    
    public var cancelButtonColor: UIColor? {
        return blurStyle == .dark ? .dark : nil
    }
    
    private var visualEffectView: UIVisualEffectView? {
        if let presentationController = presentationController, presentationController.responds(to: Selector(("popoverView"))), let view = presentationController.value(forKey: "popoverView") as? UIView // We're on an iPad and visual effect view is in a different place.
        {
            return view.recursiveSubviews.flatMap({$0 as? UIVisualEffectView}).first
        }
        
        return view.recursiveSubviews.flatMap({$0 as? UIVisualEffectView}).first
    }
    
    private var cancelActionView: UIView? {
        return view.recursiveSubviews.flatMap({$0 as? UILabel}).first(where: {$0.text == "Cancel"})?.superview?.superview
    }
    
    public convenience init(title: String?, message: String?, preferredStyle: UIAlertControllerStyle, blurStyle: UIBlurEffectStyle) {
        self.init(title: title, message: message, preferredStyle: preferredStyle)
        self.blurStyle = blurStyle
    }
}
