

import Foundation

extension String {
    
    var localized: String {
        guard let bundle = Bundle(identifier: "com.popcorntimetv.popcornkit") else {
            fatalError()
        }
        return NSLocalizedString(self, bundle: bundle, comment: "")
    }
    
    mutating func localize() {
        self = localized
    }
}
