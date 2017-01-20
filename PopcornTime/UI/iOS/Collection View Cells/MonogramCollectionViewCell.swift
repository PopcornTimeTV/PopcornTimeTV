

import Foundation

class MonogramCollectionViewCell: UICollectionViewCell {
    @IBOutlet var headshotImageView: UIImageView!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var subtitleLabel: UILabel?
    @IBOutlet var initialsLabel: UILabel!
    @IBOutlet var noImageVisualEffectView: UIVisualEffectView!
    @IBOutlet var circularView: CircularView!
    
    
    override func layoutSubviews() {
        super.layoutSubviews()
        circularView.cornerRadius = bounds.width/2.0
    }
}
