

import Foundation
import UIKit.UIAlertController

private var window: UIWindow!

extension UIAlertController {

    private struct AssociatedKey {
       static var window:   UInt8 = 0
    }

    var window: UIWindow? {
        get {
          return objc_getAssociatedObject(self, &AssociatedKey.window) as? UIWindow
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKey.window, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    open override func viewDidDisappear(_ animated: Bool) {
      super.viewDidDisappear(animated)
      window?.isHidden = true
      window = nil
    }
    
    func show(animated flag: Bool, completion: (() -> Void)? = nil) {
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = UIViewController()
        window?.windowLevel = UIWindow.Level.alert
        window?.makeKeyAndVisible()
        window?.tintColor = .app
        window?.rootViewController!.present(self, animated: flag, completion: completion)
        self.window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = UIViewController()
        window?.windowLevel = UIWindow.Level.alert
        window?.makeKeyAndVisible()
        window?.tintColor = .app
        window?.rootViewController!.present(self, animated: flag, completion: completion)
    }
    
//    open override func viewDidDisappear(_ animated: Bool) {
//        super.viewDidDisappear(animated)
//        window = nil
//    }
}
