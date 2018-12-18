

import Foundation

extension UIControl.State: Hashable {
    
    public var hashValue: Int {
        return Int(rawValue)
    }
}
