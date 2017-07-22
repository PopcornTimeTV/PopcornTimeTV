

import Foundation

class DownloadDetailTableViewCell: UITableViewCell {
    
    @IBOutlet private var _textLabel: UILabel?
    @IBOutlet private var _detailTextLabel: UILabel?
    @IBOutlet var leftDetailLabel: UILabel?
    
    override var textLabel: UILabel? {
        return _textLabel
    }
    
    override var detailTextLabel: UILabel? {
        return _detailTextLabel
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        invalidateAppearance()
    }
    
    func invalidateAppearance() {
        let pallette: ColorPallete = isFocused ? .dark : .light
        textLabel?.textColor = pallette.primary
        detailTextLabel?.textColor = pallette.secondary
        leftDetailLabel?.textColor = pallette.secondary
    }
}
