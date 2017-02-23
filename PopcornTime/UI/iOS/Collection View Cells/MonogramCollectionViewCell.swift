

import Foundation

class MonogramCollectionViewCell: BaseCollectionViewCell {
    
    @IBOutlet var headshotImageView: UIImageView!
    @IBOutlet var subtitleLabel: UILabel!
    @IBOutlet var initialsLabel: UILabel!
    @IBOutlet var noImageVisualEffectView: UIVisualEffectView!
    @IBOutlet var circularView: CircularView!
    @IBOutlet var titleLabel: UILabel!
    
    
    override func layoutSubviews() {
        super.layoutSubviews()
        circularView.cornerRadius = bounds.width/2.0
    }
}
