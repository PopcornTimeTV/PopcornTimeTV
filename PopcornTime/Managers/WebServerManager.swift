

import Foundation
import GCDWebServer


class WebServerManager: NSObject {
    var webServer: GCDWebServer!

    class func sharedManager() -> WebServerManager {
        struct Struct {
            static let Instance = WebServerManager()
        }
        return Struct.Instance
    }

    override init() {
        super.init()
    }

    func startServer(port: UInt) {

        if let _ = self.webServer {
            self.webServer.stop()
        } else {
            self.webServer = GCDWebServer()
        }

        let paths = NSSearchPathForDirectoriesInDomains(.CachesDirectory, .UserDomainMask, true)
        if let cachesDirectory = paths.first {
            do {
                let fileManager = NSFileManager.defaultManager()
                var isDir: ObjCBool = false
                var downloadsExists = false
                let downloadsDirectory = cachesDirectory.stringByAppendingPathComponent("Downloads")
                if fileManager.fileExistsAtPath(downloadsDirectory, isDirectory: &isDir) {
                    if isDir {
                        downloadsExists = true
                    }
                }

                if !downloadsExists {
                    try NSFileManager.defaultManager().createDirectoryAtPath(downloadsDirectory, withIntermediateDirectories: false, attributes: nil)
                }

                webServer.addGETHandlerForBasePath("/", directoryPath: downloadsDirectory, indexFilename: nil, cacheAge: 3600, allowRangeRequests: true)
                webServer.startWithPort(port, bonjourName: "PopcornTimeTV")

            } catch let error as NSError {
                print("Error finding Downloads: \(error)")
            }
        }
    }

    func stopServer() {
        if let _ = self.webServer {
            self.webServer.stop()
        }
    }

    // Return IP address of WiFi interface (en0) as a String, or `nil`
    func getWiFiAddress() -> String? {
        var address: String?

        // Get list of all interfaces on the local machine:
        var ifaddr: UnsafeMutablePointer<ifaddrs> = nil
        if getifaddrs(&ifaddr) == 0 {

            // For each interface ...
            var ptr = ifaddr
            while ptr != nil {
                defer { ptr = ptr.memory.ifa_next }

                let interface = ptr.memory

                // Check for IPv4 or IPv6 interface:
                let addrFamily = interface.ifa_addr.memory.sa_family
                if addrFamily == UInt8(AF_INET) || addrFamily == UInt8(AF_INET6) {

                    // Check interface name:
                    if let name = String.fromCString(interface.ifa_name) where name == "en0" {

                        // Convert interface address to a human readable string:
                        var addr = interface.ifa_addr.memory
                        var hostname = [CChar](count: Int(NI_MAXHOST), repeatedValue: 0)
                        getnameinfo(&addr, socklen_t(interface.ifa_addr.memory.sa_len),
                                    &hostname, socklen_t(hostname.count),
                                    nil, socklen_t(0), NI_NUMERICHOST)
                        address = String.fromCString(hostname)
                    }
                }
            }
            freeifaddrs(ifaddr)
        }

        return address
    }

    func getLANAddress() -> String? {
        var address: String?

        // Get list of all interfaces on the local machine:
        var ifaddr: UnsafeMutablePointer<ifaddrs> = nil
        if getifaddrs(&ifaddr) == 0 {

            // For each interface ...
            var ptr = ifaddr
            while ptr != nil {
                defer { ptr = ptr.memory.ifa_next }

                let interface = ptr.memory

                // Check for IPv4 or IPv6 interface:
                let addrFamily = interface.ifa_addr.memory.sa_family
                if addrFamily == UInt8(AF_INET) || addrFamily == UInt8(AF_INET6) {

                    // Check interface name:
                    if let name = String.fromCString(interface.ifa_name) where name == "en1" {

                        // Convert interface address to a human readable string:
                        var addr = interface.ifa_addr.memory
                        var hostname = [CChar](count: Int(NI_MAXHOST), repeatedValue: 0)
                        getnameinfo(&addr, socklen_t(interface.ifa_addr.memory.sa_len),
                                    &hostname, socklen_t(hostname.count),
                                    nil, socklen_t(0), NI_NUMERICHOST)
                        address = String.fromCString(hostname)
                    }
                }
            }
            freeifaddrs(ifaddr)
        }

        return address
    }
}
