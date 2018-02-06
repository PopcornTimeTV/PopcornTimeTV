

import Foundation

extension UIViewController: Object {
    
    var statusBarHeight: CGFloat {
        let statusBarSize = UIApplication.shared.statusBarFrame.size
        return Swift.min(statusBarSize.width, statusBarSize.height)
    }
    
    static func awake() {
        
        DispatchQueue.once {
            exchangeImplementations(originalSelector: #selector(getter: preferredStatusBarStyle), swizzledSelector: #selector(getter: pct_preferredStatusBarStyle))
        }
    }
    
    class func exchangeImplementations(originalSelector: Selector, swizzledSelector: Selector) {
        let originalMethod = class_getInstanceMethod(self, originalSelector)
        let swizzledMethod = class_getInstanceMethod(self, swizzledSelector)
        method_exchangeImplementations(originalMethod!, swizzledMethod!)
    }
    
    
    @objc private var pct_preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
}
