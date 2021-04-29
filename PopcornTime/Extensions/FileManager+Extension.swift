

import Foundation

extension FileManager {
    func fileSize(atPath path: String) -> Int64 {
        return (try? attributesOfItem(atPath: path)[.size] as? Int64) ?? 0
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
