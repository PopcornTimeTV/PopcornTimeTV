

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

// MARK: - NSFileManager

extension FileManager {
    func fileSize(atPath path: String) -> Int64 {
        do {
            return try (attributesOfItem(atPath: path)[FileAttributeKey.size]! as AnyObject).int64Value
        } catch {
            print("Error reading filesize: \(error)")
            return 0
        }
    }
    
    func folderSize(atPath path: String) -> Int64 {
        var size: Int64 = 0
        do {
            for file in try subpathsOfDirectory(atPath: path) {
                size += fileSize(atPath: (path as NSString).appendingPathComponent(file) as String)
            }
        } catch {
            print("Error reading directory.")
        }
        return size
    }
}
