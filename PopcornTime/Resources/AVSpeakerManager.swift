

import Foundation

class AVSpeakerManager: NSObject {
    
    let instance: NSObject
    
    override init() {
        let AVSpeakerManager = NSClassFromString("AVSpeakerManager") as! NSObject.Type
        instance = AVSpeakerManager.init()
        
        super.init()
    }
    
    var alternateRoutesAvailable: Bool {
        return instance.value(forKey: "alternateRoutesAvailable") as? Bool ?? false
    }
    
    var selectedRoute: AVAudioRoute? {
        if let route = instance.value(forKey: "selectedRoute") as? NSObject {
            return AVAudioRoute(from: route)
        }
        return nil
    }
    
    var defaultRoute: AVAudioRoute? {
        if let route = instance.value(forKey: "defaultRoute") as? NSObject {
            return AVAudioRoute(from: route)
        }
        return nil
    }
    
    var speakerRoutes: [AVAudioRoute] {
        if let routes = instance.value(forKey: "speakerRoutes") as? [NSObject] {
            return routes.compactMap({AVAudioRoute(from: $0)})
        }
        return []
    }
    
    func select(route: AVAudioRoute, with password: String? = nil) {
        instance.perform(Selector(("selectRoute:withPassword:")), with: route.instance, with: password)
    }
}
