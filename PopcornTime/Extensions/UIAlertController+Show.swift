

import Foundation
import UIKit.UIAlertController

extension UIAlertController {
    
    func show() {
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = UIViewController()
        window.windowLevel = UIWindowLevelAlert + 1
        window.makeKeyAndVisible()
        window.rootViewController!.present(self, animated: true)
    }
}
