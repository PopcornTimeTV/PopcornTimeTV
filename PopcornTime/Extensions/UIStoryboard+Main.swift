

import Foundation

extension UIStoryboard {
    
    static var main: UIStoryboard {
        if UIDevice.current.userInterfaceIdiom == .tv {
            return UIStoryboard(name: "tvOS", bundle: nil)
        } else {
            return UIStoryboard(name: "iOS", bundle: nil)
        }
    }
}
