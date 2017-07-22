

import Foundation

extension UIControlState: Hashable {
    
    public var hashValue: Int {
        return Int(rawValue)
    }
}
