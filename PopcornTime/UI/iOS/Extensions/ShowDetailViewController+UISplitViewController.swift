
import Foundation

extension UISplitViewController {
    
    private struct AssociatedKeys {
        static var windowKey = "UISplitViewController.windowKey"
    }
    
    @nonobjc var window: UIWindow? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.windowKey) as? UIWindow
        } set (value) {
            objc_setAssociatedObject(self, &AssociatedKeys.windowKey, value, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    
    /** 
     Stops UISplitViewController delegates being called and messing with modally presented view controllers we do not want added to UISplitViewController.
     
     This is achieved by instantiating a separate UIWindow and presenting that instead.
     
     - Parameter viewControllerToPresent:   The viewController to be presented.
     - Parameter animated:                  Whether or not you want the presentation to be animated.
     - Parameter completion:                Optional completion handler called when request is finished. Defaults to `nil`.
     */
    func presentOverTop(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)? = nil) {
        
        window = UIWindow(frame: CGRect(origin: CGPoint(x: 0, y: UIScreen.main.bounds.height), size: UIScreen.main.bounds.size))
        window?.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        window?.rootViewController = viewControllerToPresent
        
        if flag {
            UIView.animate(withDuration: 0.6, delay: 0.0, usingSpringWithDamping: 300.0, initialSpringVelocity: 5.0, options: [.allowUserInteraction, .beginFromCurrentState], animations: { 
                self.window?.makeKeyAndVisible()
                self.window?.frame.origin.y = 0
            }, completion: {_ in
                completion?()
            })
        } else {
            window?.makeKeyAndVisible()
            self.window?.frame.origin.y = 0
            completion?()
        }
    }
    
    /**
     Used for dismissing viewControllers presented via `presentOverTop:animated:completion:`.
     
     - Parameter animated:                  Whether or not you want the presentation to be animated.
     - Parameter completion:                Optional completion handler called when request is finished. Defaults to `nil`.
     */
    func dismissTopWindow(animated flag: Bool, completion: (() -> Void)? = nil) {
        if flag {
            UIView.animate(withDuration: 0.6, delay: 0.0, usingSpringWithDamping: 300.0, initialSpringVelocity: 5.0, options: [.allowUserInteraction, .beginFromCurrentState], animations: {
                self.window?.resignKey()
                self.window?.frame.origin.y = UIScreen.main.bounds.height
            }, completion: {_ in
                self.window = nil
                
                completion?()
            })
        } else {
            window?.resignKey()
            window = nil
            
            completion?()
        }
    }
}
