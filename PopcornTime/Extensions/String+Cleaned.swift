

import Foundation

extension String {

    var cleaned: String {
        var s = replacingOccurrences(of: "&amp;", with: "&")
        // If ampersands are straight up replaced with &amp, it could mess up already formatted data.
        s = s.replacingOccurrences(of: "&", with: "&amp;")
        s = s.replacingOccurrences(of: "<", with: "&lt;")
        s = s.replacingOccurrences(of: ">", with: "&gt;")
        s = s.replacingOccurrences(of: "'", with: "&apos;")
        s = s.replacingOccurrences(of: "\"", with: "&quot;")
        return s
    }

    var urlEncoded: String? {
        return addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)
    }

}
