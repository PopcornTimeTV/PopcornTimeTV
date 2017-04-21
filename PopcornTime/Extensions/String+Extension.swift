

import Foundation
import UIKit.NSAttributedString

extension String {
    
    var localized: String {
        return Bundle.main.localizedString(forKey: self, value: self, table: nil)
    }
    
    mutating func localize() {
        self = localized
    }
    
    func slice(from start: String, to: String) -> String? {
        return (range(of: start)?.upperBound).flatMap { sInd in
            let eInd = range(of: to, range: sInd..<endIndex)
            if eInd != nil {
                return (eInd?.lowerBound).map { eInd in
                    return substring(with: sInd..<eInd)
                }
            }
            return substring(with: sInd..<endIndex)
        }
    }
    
    var slugged: String {
        let allowedCharacters = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-")
        
        let cocoaString = NSMutableString(string: self) as CFMutableString
        CFStringTransform(cocoaString, nil, kCFStringTransformToLatin, false)
        CFStringTransform(cocoaString, nil, kCFStringTransformStripCombiningMarks, false)
        CFStringLowercase(cocoaString, .none)
        
        return String(cocoaString)
            .components(separatedBy: allowedCharacters.inverted)
            .filter { $0 != "" }
            .joined(separator: "-")
    }
    
    static func random(of length: Int) -> String {
        let alphabet = "-_1234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
        return String((0..<length).map { _ -> Character in
            return alphabet[alphabet.characters.index(alphabet.startIndex, offsetBy: Int(arc4random_uniform(UInt32(alphabet.characters.count))))]
        })
    }
    
    var queryString: [String: String] {
        var queryStringDictionary = [String: String]()
        let urlComponents = components(separatedBy: "&")
        for keyValuePair in urlComponents {
            let pairComponents = keyValuePair.components(separatedBy: "=")
            let key = pairComponents.first?.removingPercentEncoding
            let value = pairComponents.last?.removingPercentEncoding
            queryStringDictionary[key!] = value!
        }
        return queryStringDictionary
    }
    
    init?(htmlEncoded string: String) {
        self.init()
        
        guard let encodedData = string.data(using: .utf8) else {
            return nil
        }
        
        let attributedOptions: [String : Any] = [
            NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType,
            NSCharacterEncodingDocumentAttribute: String.Encoding.utf8.rawValue
        ]
        
        if let attributedString = try? NSAttributedString(data: encodedData, options: attributedOptions, documentAttributes: nil) {
            self = attributedString.string
        } else {
            return nil
        }
    }
    
    var removingHtmlEncoding: String? {
        return String(htmlEncoded: self)
    }
    
    mutating func removeHtmlEncoding() throws {
        if let new = removingHtmlEncoding {
            self = new
        } else {
            throw NSError()
        }
    }
}
