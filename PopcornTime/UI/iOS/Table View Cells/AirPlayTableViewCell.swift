

import UIKit

class AirPlayTableViewCell: UITableViewCell {
    @IBOutlet var titleLabel: UILabel?
    @IBOutlet var airImageView: UIImageView?
    @IBOutlet var checkmarkAccessory: UIButton?
    @IBOutlet var mirrorSwitch: UISwitch?
    var picked: Bool = false {
        didSet {
            if picked {
                checkmarkAccessory?.isHidden = false
            } else {
                checkmarkAccessory?.isHidden = true
            }
        }
    }

}
