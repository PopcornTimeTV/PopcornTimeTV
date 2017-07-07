

import Foundation

class DescriptionCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet var keyLabel: UILabel!
    @IBOutlet var valueLabel: UILabel!
    
    var isDark = true {
        didSet {
            guard oldValue != isDark else { return }
            
            let colorPallete: ColorPallete = isDark ? .light : .dark
            
            keyLabel.textColor = colorPallete.primary
            valueLabel.textColor = colorPallete.secondary
        }
    }
    
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
