

import Foundation

extension UIViewController {
    
    @objc private func pctFocusedViewDidChange() {
        NotificationCenter.default.post(name: .UIViewControllerFocusedViewDidChange, object: self)
        self.pctFocusedViewDidChange()
    }
    
    open override class func initialize() {
        
        
        if self !== UIViewController.self {
            return
        }
        
        DispatchQueue.once() {
            exchangeImplementations(originalSelector: Selector(("focusedViewDidChange")), swizzledSelector: #selector(pctFocusedViewDidChange))
        }
    }
    
    class func exchangeImplementations(originalSelector: Selector, swizzledSelector: Selector) {
        let originalMethod = class_getInstanceMethod(self, originalSelector)
        let swizzledMethod = class_getInstanceMethod(self, swizzledSelector)
        method_exchangeImplementations(originalMethod, swizzledMethod)
    }
}
