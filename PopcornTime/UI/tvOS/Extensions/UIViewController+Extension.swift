

import Foundation

extension UIViewController: Object {
    
    @objc private func pctFocusedViewDidChange() {
        NotificationCenter.default.post(name: .UIViewControllerFocusedViewDidChange, object: self)
        self.pctFocusedViewDidChange()
    }
    
    
    
    class func awake() {

        DispatchQueue.once {
            exchangeImplementations(originalSelector: Selector(("focusedViewDidChange")), swizzledSelector: #selector(pctFocusedViewDidChange))
        }
    }
    
    class func exchangeImplementations(originalSelector: Selector, swizzledSelector: Selector) {
        let originalMethod = class_getInstanceMethod(self, originalSelector)
        let swizzledMethod = class_getInstanceMethod(self, swizzledSelector)
        method_exchangeImplementations(originalMethod, swizzledMethod)
    }
}
