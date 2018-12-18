

import UIKit
import GoogleCast.GCKCommon

class CastIconButton: UIButton {
    
    var status: GCKCastState = .noDevicesAvailable {
        didSet {
            switch status {
            case .noDevicesAvailable:
                imageView!.stopAnimating()
                isHidden = true
            case .notConnected:
                isHidden = false
                imageView!.stopAnimating()
                setImage(castOff, for: .normal)
            case .connecting:
                isHidden = false
                setImage(castOff, for: .normal)
                imageView!.startAnimating()
            case .connected:
                isHidden = false
                imageView!.stopAnimating()
                setImage(castOn, for: .normal)
            }
        }
    }
    
    let castOff = UIImage(named: "CastOff")
    let castOn = UIImage(named: "CastOn")
    
    var castConnecting: [UIImage] {
        return (0...2).compactMap({UIImage(named: "CastOn\($0)")}).appending(UIImage(named: "CastOn1")!).compactMap({$0.colored(tintColor)})
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        imageView?.animationImages = castConnecting
        imageView?.animationDuration = 2
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        imageView?.animationImages = castConnecting
        imageView?.animationDuration = 2
    }
    
    override func tintColorDidChange() {
        super.tintColorDidChange()
        
        imageView?.animationImages = castConnecting
    }
}
