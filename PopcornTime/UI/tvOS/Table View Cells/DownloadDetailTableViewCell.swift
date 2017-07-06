

import Foundation

class DownloadDetailTableViewCell: UITableViewCell {
    
    private struct ColorPallete {
        let primary: UIColor
        let secondary: UIColor
        let tertiary: UIColor
        
        private init(primary: UIColor, secondary: UIColor, tertiary: UIColor) {
            self.primary = primary
            self.secondary = secondary
            self.tertiary = tertiary
        }
        
        static let light = ColorPallete(primary: .white, secondary: UIColor.white.withAlphaComponent(0.667), tertiary: UIColor.white.withAlphaComponent(0.333))
        static let dark  = ColorPallete(primary: .black, secondary: UIColor.black.withAlphaComponent(0.667), tertiary: UIColor.black.withAlphaComponent(0.333))
    }
    
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
