

import Foundation

extension String {

    var lastPathComponent: String {

        get {
            return (self as NSString).lastPathComponent
        }
    }

    var pathExtension: String {

        get {

            return (self as NSString).pathExtension
        }
    }

    var stringByDeletingLastPathComponent: String {

        get {

            return (self as NSString).stringByDeletingLastPathComponent
        }
    }

    var stringByDeletingPathExtension: String {

        get {

            return (self as NSString).stringByDeletingPathExtension
        }
    }

    var pathComponents: [String] {

        get {

            return (self as NSString).pathComponents
        }
    }

    func stringByAppendingPathComponent(path: String) -> String {

        let nsSt = self as NSString

        return nsSt.stringByAppendingPathComponent(path)
    }

    func stringByAppendingPathExtension(ext: String) -> String? {

        let nsSt = self as NSString

        return nsSt.stringByAppendingPathExtension(ext)
    }
}
