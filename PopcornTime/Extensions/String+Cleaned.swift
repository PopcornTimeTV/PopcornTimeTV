

import Foundation

extension String {

    var cleaned: String {
        var s = replacingOccurrences(of: "&amp;", with: "&")
        s = s.replacingOccurrences(of: "&", with: "&amp;")
        s = s.replacingOccurrences(of: "\"", with: "&quot;")
        return s
    }

    var urlEncoded: String? {
        return addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)
    }

}
