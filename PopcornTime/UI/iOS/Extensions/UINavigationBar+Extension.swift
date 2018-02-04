

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
                backgroundColor = .clear
                tintColor = .white
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
    
    open override func tintColorDidChange() {
        super.tintColorDidChange()
        
        self.items?.flatMap({ (item) -> [UIView]? in
            let right = item.rightBarButtonItems?.flatMap({$0.customView}) ?? []
            let left = item.leftBarButtonItems?.flatMap({$0.customView}) ?? []
            
            return right.appending(left)
        }).flatMap({$0}).forEach({$0.tintColor = tintColor})
    }
}
