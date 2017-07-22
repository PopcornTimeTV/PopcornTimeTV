

import Foundation

extension Bundle {
    
    /// Returns the localized amalgamation of the `CFBundleShortVersionString` and `CFBundleVersion` strings separated by the current locale's decimal separator.
    var localizedVersion: String {
        let bundle = Bundle.main
        let version = [bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString"), bundle.object(forInfoDictionaryKey: "CFBundleVersion")].flatMap({$0 as? String}).joined(separator: ".").components(separatedBy: ".")
        return version.flatMap {
            if let value = Int($0) {
                return NumberFormatter.localizedString(from: NSNumber(value: value), number: .none)
            }
            return nil
        }.joined(separator: Locale.current.decimalSeparator ?? ".")
    }
}
