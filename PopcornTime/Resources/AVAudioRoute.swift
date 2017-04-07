

import Foundation

class AVAudioRoute: NSObject {
    
    let instance: NSObject
    
    enum DeviceType: Int {
        case `default` = 0
    }
    
    override init() {
        let AVAudioRoute = NSClassFromString("AVAudioRoute") as! NSObject.Type
        instance = AVAudioRoute.init()
        
        super.init()
    }
    
    class var `default`: AVAudioRoute? {
        return (NSClassFromString("AVAudioRoute") as! NSObject.Type).perform(Selector(("defaultAudioRoute"))).takeUnretainedValue() as? AVAudioRoute
    }
    
    init?(from instance: NSObject) {
        guard type(of: instance) == NSClassFromString("AVAudioRoute") else { return nil }
        self.instance = instance
        
        super.init()
    }
    
    var deviceType: DeviceType {
        return DeviceType(rawValue: instance.value(forKey: "deviceType") as? Int ?? 0)!
    }
    
    var isPasswordProtected: Bool {
        return instance.value(forKey: "passwordOrPINRequired") as? Bool ?? false
    }
    
    var identifier: String {
        return instance.value(forKey: "identifier") as? String ?? ""
    }
    
    var name: String {
        return instance.value(forKey: "routeName") as? String ?? ""
    }
    
    var isSelected: Bool {
        return instance.value(forKey: "isSelected") as? Bool ?? false
    }
    
    var isDefault: Bool {
        return instance.value(forKey: "isDefaultRoute") as? Bool ?? false
    }
    
    override var description: String {
        return "<\(type(of: self)): \(String(format: "%p", unsafeBitCast(self, to: Int.self))); passwordProtected = \(isPasswordProtected); identifier = '\(identifier)'; name = '\(name)', selected = \(isSelected), default:\(isDefault)>"
    }
}
