

import Foundation

class AVSpeakerManager: NSObject {
    
    private let manager: NSObject
    
    override init() {
        let AVSpeakerManager = NSClassFromString("AVSpeakerManager") as! NSObject.Type
        manager = AVSpeakerManager.init()
        
        super.init()
    }
    
    var alternateRoutesAvailable: Bool {
        return manager.value(forKey: "alternateRoutesAvailable") as? Bool ?? false
    }
    
    var selectedRoute: AVAudioRoute? {
        if let route = manager.value(forKey: "selectedRoute") as? NSObject {
            return AVAudioRoute(from: route)
        }
        return nil
    }
    
    var defaultRoute: AVAudioRoute? {
        if let route = manager.value(forKey: "defaultRoute") as? NSObject {
            return AVAudioRoute(from: route)
        }
        return nil
    }
    
    var speakerRoutes: [AVAudioRoute] {
        if let routes = manager.value(forKey: "speakerRoutes") as? [NSObject] {
            return routes.flatMap({AVAudioRoute(from: $0)})
        }
        return []
    }
    
    @discardableResult func select(route: AVAudioRoute, with password: String? = nil) -> Bool {
        return manager.perform(Selector(("selectRoute:withPassword:")), with: route.instance, with: password).takeUnretainedValue() as? Bool ?? false
    }
}
