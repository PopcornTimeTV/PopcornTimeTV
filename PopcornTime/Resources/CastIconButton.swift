

import UIKit
import GoogleCast.GCKCommon

class CastIconButton: UIButton {
    
    var status: GCKCastState = .noDevicesAvailable {
        didSet {
            switch status {
            case .noDevicesAvailable:
                imageView?.stopAnimating()
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
                tintColor = UIColor.app
            }
        }
    }
    let castOff = UIImage(named: "CastOff")!
    let castOn = UIImage(named: "CastOn")!
    var castConnecting: [UIImage] {
      return [UIImage(named: "CastOn0")!.colored(superview?.tintColor), UIImage(named: "CastOn1")!.colored(superview?.tintColor), UIImage(named: "CastOn2")!.colored(superview?.tintColor), UIImage(named: "CastOn1")!.colored(superview?.tintColor)]
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
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        customView = CastIconButton(frame: CGRect(x: 0,y: 0,width: 26,height: 26))
    }
}



