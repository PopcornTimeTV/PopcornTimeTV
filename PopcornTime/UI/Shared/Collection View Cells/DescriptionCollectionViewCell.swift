

import Foundation

class DescriptionCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet var keyLabel: UILabel!
    @IBOutlet var valueLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        if UIApplication.shared.userInterfaceLayoutDirection == .leftToRight {
            keyLabel.textAlignment = .right
            valueLabel.textAlignment = .left
        } else {
            keyLabel.textAlignment = .left
            valueLabel.textAlignment = .right
        }
    }
}
