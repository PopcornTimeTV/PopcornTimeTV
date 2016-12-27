

import UIKit

protocol StreamToDevicesTableViewCellDelegate: class {
    func routingCell(_ cell: StreamToDevicesTableViewCell, mirroringSwitchValueDidChange on: Bool)
}

class StreamToDevicesTableViewCell: UITableViewCell {
    
    @IBOutlet var iconImageView: UIImageView!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var mirroringLabel: UILabel!
    @IBOutlet var mirroringSeparatorView: UIView!
    @IBOutlet var mirroringSwitch: UISwitch!
    @IBOutlet var checkmarkAccessory: UIButton!
    
    weak var delegate: StreamToDevicesTableViewCellDelegate?
    
    var mirroringSwitchVisible: Bool = false {
        didSet {
            delegate?.routingCell(self, mirroringSwitchValueDidChange: mirroringSwitchVisible)
        }
    }
    
    @IBAction func switched(_ sender: UISwitch) {
        mirroringSwitchVisible = sender.isOn
    }
    
    var isPicked: Bool = false {
        didSet {
            checkmarkAccessory?.isHidden = !isPicked
        }
    }

}
