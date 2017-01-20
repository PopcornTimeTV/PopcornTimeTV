

import Foundation

extension UINavigationBar {
    
    private struct AssociatedKeys {
        static var backgroundKey = "UINavigationBar.backgroundKey"
        static var hairlineKey = "UINavigationBar.hairlineKey"
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
    
    var isHairlineHidden: Bool {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.hairlineKey) as? Bool ?? false
        } set (hidden) {
            objc_setAssociatedObject(self, &AssociatedKeys.hairlineKey, hidden, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            
            hairlineView?.isHidden = hidden
        }
    }
    
    private var hairlineView: UIImageView? {
        return recursiveSubviews.flatMap({ $0 as? UIImageView }).filter({ $0.bounds.size.width == self.bounds.size.width }).first(where: { $0.bounds.size.height <= 2 })
    }
}
