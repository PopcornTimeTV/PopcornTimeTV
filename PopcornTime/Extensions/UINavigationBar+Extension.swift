

import Foundation

extension UINavigationBar {
    
    private struct AssociatedKeys {
        static var backgroundKey = "UINavigationBar.backgroundKey"
    }
    
    var isBackgroundHidden: Bool {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.backgroundKey) as? Bool ?? false
        } set (hidden) {
            objc_setAssociatedObject(self, &AssociatedKeys.backgroundKey, hidden, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            
            if hidden {
                setBackgroundImage(UIImage(), for: .default)
                shadowImage = UIImage()
                backgroundColor = UIColor.clear
                tintColor = UIColor.white
            } else {
                setBackgroundImage(nil, for: .default)
                shadowImage = nil
            }
        }
    }
}
