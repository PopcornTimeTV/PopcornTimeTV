

import Foundation
import MediaPlayer
import PopcornKit

class AirPlayTableViewCell: UITableViewCell {
    
    let volumeView = MPVolumeView()
    
    var routingController: MPAVRoutingController {
        return volumeView.value(forKey: "routingController") as! MPAVRoutingController
    }
    
    var routeButton: UIButton {
        return volumeView.value(forKey: "_routeButton") as! UIButton
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        volumeView.showsVolumeSlider = false
        volumeView.showsRouteButton = true
        
        addSubview(volumeView)
        
        NotificationCenter.default.addObserver(self, selector: #selector(activeRouteDidChange), name: .MPVolumeViewWirelessRouteActiveDidChange, object: nil)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        volumeView.frame = bounds
        routeButton.isHidden = true
    }
    
    func activeRouteDidChange() {
        if let picked = routingController.pickedRoute, let video = picked.wirelessDisplay {
            let alertController = UIAlertController(title: "Mirroring route detected", message: "Would you like to mirror current display to device?", preferredStyle: .alert)
            
            alertController.addAction(UIAlertAction(title: "Yes", style: .default, handler: { (_) in
                self.routingController.pick(video)
            }))
            
            alertController.addAction(UIAlertAction(title: "No", style: .cancel, handler: nil))
            
            parentViewController?.present(alertController, animated: true, completion: nil)
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: .MPVolumeViewWirelessRouteActiveDidChange, object: nil)
    }
}
