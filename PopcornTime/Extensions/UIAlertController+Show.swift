

import Foundation
import UIKit.UIAlertController

extension UIAlertController {
    
    func show(animated flag: Bool, completion: (() -> Void)? = nil) {
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = UIViewController()
        window.windowLevel = UIWindow.Level.alert
        window.makeKeyAndVisible()
        window.tintColor = .app
        window.rootViewController!.present(self, animated: flag, completion: completion)
    }
}
