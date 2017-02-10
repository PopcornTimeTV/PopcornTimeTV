

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
                tintColor = superview?.tintColor
            case .connecting:
                isHidden = false
                tintColor = superview?.tintColor
                setImage(castOff, for: .normal)
                imageView!.startAnimating()
            case .connected:
                isHidden = false
                imageView!.stopAnimating()
                setImage(castOn, for: .normal)
                tintColor = .app
            }
        }
    }
    
    let castOff = UIImage(named: "CastOff")
    let castOn = UIImage(named: "CastOn")
    
    var castConnecting: [UIImage] {
        return (0...2).flatMap({UIImage(named: "CastOn\($0)")}).appending(UIImage(named: "CastOn1")!)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        imageView!.animationImages = castConnecting
        imageView!.animationDuration = 2
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        imageView!.animationImages = castConnecting
        imageView!.animationDuration = 2
    }
}

class CastIconBarButtonItem: UIBarButtonItem {
    
    var status: GCKCastState {
        get {
            return button.status
        } set {
            button.status = newValue
        }
    }
    
    var button = CastIconButton(frame: CGRect(x: 0, y: 0, width: 26, height: 26))
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        customView = button
    }
}
