

import Foundation

extension String {
    
    var localized: String {
        return NSLocalizedString(self, comment: "")
    }
    
    mutating func localize() {
        self = localized
    }
}
