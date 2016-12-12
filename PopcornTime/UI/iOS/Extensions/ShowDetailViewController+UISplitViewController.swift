
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
        
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        window?.rootViewController = viewControllerToPresent
        
        if flag {
            window?.alpha = 0.0
            window?.backgroundColor = .clear
            
            UIView.beginAnimations(nil, context: nil)
            
            window?.makeKeyAndVisible()
            window?.alpha = 1.0
            
            UIView.commitAnimations()
        } else {
            window?.makeKeyAndVisible()
        }
        
        completion?()
    }
    
    /**
     Used for dismissing viewControllers presented via `presentOverTop:animated:completion:`.
     
     - Parameter animated:                  Whether or not you want the presentation to be animated.
     - Parameter completion:                Optional completion handler called when request is finished. Defaults to `nil`.
     */
    func dismissTopWindow(animated flag: Bool, completion: (() -> Void)? = nil) {
        if flag {
            window?.alpha = 1.0
            
            UIView.beginAnimations(nil, context: nil)
            
            window?.resignKey()
            window?.alpha = 0.0
            
            UIView.commitAnimations()
        } else {
            window?.resignKey()
        }
        
        window = nil
        
        completion?()
    }
}
