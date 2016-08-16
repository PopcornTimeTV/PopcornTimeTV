

import Foundation

extension String {

    var cleaned: String {
        var s = stringByReplacingOccurrencesOfString("&amp;", withString: "&")
        s = s.stringByReplacingOccurrencesOfString("&", withString: "&amp;")
        s = s.stringByReplacingOccurrencesOfString("\"", withString: "&quot;")
        return s
    }

    var slugged: String {
        let allowedCharacters = NSCharacterSet(charactersInString: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-")

        let cocoaString = NSMutableString(string: self) as CFMutableStringRef
        CFStringTransform(cocoaString, nil, kCFStringTransformToLatin, false)
        CFStringTransform(cocoaString, nil, kCFStringTransformStripCombiningMarks, false)
        CFStringLowercase(cocoaString, .None)

        return String(cocoaString)
            .componentsSeparatedByCharactersInSet(allowedCharacters.invertedSet)
            .filter { $0 != "" }
            .joinWithSeparator("-")
    }

    var urlEncoded: String? {
        return stringByAddingPercentEncodingWithAllowedCharacters(.URLHostAllowedCharacterSet())
    }

}
