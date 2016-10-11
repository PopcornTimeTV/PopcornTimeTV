

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

        let paths = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)
        if let cachesDirectory = paths.first {
            do {
                let fileManager = FileManager.default
                var isDir: ObjCBool = false
                var downloadsExists = false
                let downloadsDirectory = (cachesDirectory as NSString).appendingPathComponent("Downloads")
                if fileManager.fileExists(atPath: downloadsDirectory, isDirectory: &isDir) {
                    if isDir.boolValue {
                        downloadsExists = true
                    }
                }

                if !downloadsExists {
                    try FileManager.default.createDirectory(atPath: downloadsDirectory, withIntermediateDirectories: false, attributes: nil)
                }

                webServer.addGETHandler(forBasePath: "/", directoryPath: downloadsDirectory, indexFilename: nil, cacheAge: 3600, allowRangeRequests: true)
                webServer.start(withPort: port, bonjourName: "PopcornTimeTV")

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
        var ifaddr: UnsafeMutablePointer<ifaddrs>? = nil
        if getifaddrs(&ifaddr) == 0 {

            // For each interface ...
            var ptr = ifaddr
            while ptr != nil {
                guard let unwrappedPtr = ptr else {
                    break
                }
                defer { ptr = unwrappedPtr.pointee.ifa_next }

                let interface = unwrappedPtr.pointee

                // Check for IPv4 or IPv6 interface:
                let addrFamily = interface.ifa_addr.pointee.sa_family
                if addrFamily == UInt8(AF_INET) || addrFamily == UInt8(AF_INET6) {

                    // Check interface name:
                    let name = String(cString: interface.ifa_name)
                    if name == "en0" {
                        // Convert interface address to a human readable string:
                        var addr = interface.ifa_addr.pointee
                        var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                        getnameinfo(&addr, socklen_t(interface.ifa_addr.pointee.sa_len),
                                    &hostname, socklen_t(hostname.count),
                                    nil, socklen_t(0), NI_NUMERICHOST)
                        address = String(cString: hostname)
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
        var ifaddr: UnsafeMutablePointer<ifaddrs>? = nil
        if getifaddrs(&ifaddr) == 0 {
            
            // For each interface ...
            var ptr = ifaddr
            while ptr != nil {
                guard let unwrappedPtr = ptr else {
                    break
                }
                defer { ptr = unwrappedPtr.pointee.ifa_next }
                
                let interface = unwrappedPtr.pointee
                
                // Check for IPv4 or IPv6 interface:
                let addrFamily = interface.ifa_addr.pointee.sa_family
                if addrFamily == UInt8(AF_INET) || addrFamily == UInt8(AF_INET6) {
                    
                    // Check interface name:
                    let name = String(cString: interface.ifa_name)
                    if name == "en1" {
                        // Convert interface address to a human readable string:
                        var addr = interface.ifa_addr.pointee
                        var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                        getnameinfo(&addr, socklen_t(interface.ifa_addr.pointee.sa_len),
                                    &hostname, socklen_t(hostname.count),
                                    nil, socklen_t(0), NI_NUMERICHOST)
                        address = String(cString: hostname)
                    }
                }
            }
            freeifaddrs(ifaddr)
        }
        
        return address
    }
}
