

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
    var fontColor: UIColor = .white
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
        UserDefaults.standard.synchronize()
    }
    
    required init?(coder aDecoder: NSCoder) {
        guard let color = aDecoder.decodeObject(of: UIColor.self, forKey: "fontColor"),
            let name = aDecoder.decodeObject(of: NSString.self, forKey: "fontName") as? String,
            let rawValue = aDecoder.decodeObject(of: NSString.self, forKey: "backgroundType") as? String,
            let background = BackgroundType(rawValue: rawValue),
            let size = aDecoder.decodeObject(forKey: "fontSize") as? CGFloat,
            let encoding = aDecoder.decodeObject(of: NSString.self, forKey: "encoding") as? String else { return nil }
        self.fontSize = Float(size)
        self.fontColor = color
        self.fontName = name
        self.backgroundType = background
        self.encoding = encoding
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(CGFloat(fontSize), forKey: "fontSize")
        aCoder.encode(fontColor, forKey: "fontColor")
        aCoder.encode(fontName, forKey: "fontName")
        aCoder.encode(backgroundType.rawValue, forKey: "backgroundType")
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
