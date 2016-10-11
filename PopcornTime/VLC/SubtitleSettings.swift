

import Foundation
import UIKit

enum BackgroundType: String {
    case black = "Black"
    case white = "White"
    case blur  = "Blur"
    case none  = "None"
}

class SubtitleSettings: NSObject, NSCoding {
    
    var fontSize: Float = 16.0
    var fontColor: UIColor = UIColor.white
    var fontName: String = "system"
    var backgroundType: BackgroundType = .none
    var encoding: String = "Windows-1252"
    
    override init() {
        guard let codedData = UserDefaults.standard.data(forKey: "subtitleSettings"), let settings = NSKeyedUnarchiver.unarchiveObject(with: codedData) as? SubtitleSettings else { return }
        self.fontSize = settings.fontSize
        self.fontColor = settings.fontColor
        self.fontName = settings.fontName
        self.backgroundType = settings.backgroundType
        self.encoding = settings.encoding
    }
    
    func save() {
        UserDefaults.standard.set(NSKeyedArchiver.archivedData(withRootObject: self), forKey: "subtitleSettings")
    }
    
    required init?(coder aDecoder: NSCoder) {
        guard let size = aDecoder.decodeObject(forKey: "fontSize") as? Float,
            let color = aDecoder.decodeObject(forKey: "fontColor") as? UIColor,
            let name = aDecoder.decodeObject(forKey: "fontName") as? String,
            let background = aDecoder.decodeObject(forKey: "backgroundType") as? BackgroundType,
            let encoding = aDecoder.decodeObject(forKey: "encoding") as? String else { return nil }
        self.fontSize = size
        self.fontColor = color
        self.fontName = name
        self.backgroundType = background
        self.encoding = encoding
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(fontSize, forKey: "fontSize")
        aCoder.encode(fontColor, forKey: "fontColor")
        aCoder.encode(fontName, forKey: "fontName")
        aCoder.encode(backgroundType, forKey: "backgroundType")
        aCoder.encode(encoding, forKey: "encoding")
    }
    
    
    override var description: String {
        return "<\(type(of: self)) size: \(fontSize) color: \(fontColor) fname: \(fontName)>"
    }
    
    var attributes: [String: Any] {
        
        let font = fontName == "system" ? UIFont.systemFont(ofSize: CGFloat(fontSize)) : UIFont(name: fontName, size: CGFloat(fontSize))
        
        let lineSpace = CGFloat(roundf(1.5 * fontSize))

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        paragraphStyle.lineHeightMultiple = lineSpace
        paragraphStyle.maximumLineHeight = lineSpace
        paragraphStyle.minimumLineHeight = lineSpace
        paragraphStyle.paragraphSpacingBefore = 0
        
        return [NSFontAttributeName: font, NSParagraphStyleAttributeName: paragraphStyle, NSForegroundColorAttributeName: fontColor]
    }
    
}
