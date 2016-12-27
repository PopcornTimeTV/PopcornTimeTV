

import Foundation
import UIKit

class SubtitleSettings: NSObject, NSCoding {
    
    var size: Float = 16.0
    var color: UIColor = .white
    var encoding: String = "Windows-1252"
    var language: String? = nil
    var font: UIFont = UIFont.systemFont(ofSize: 16)
    var style: UIFont.FontStyle = .normal
    
    override init() {
        guard let codedData = UserDefaults.standard.data(forKey: "subtitleSettings"), let settings = NSKeyedUnarchiver.unarchiveObject(with: codedData) as? SubtitleSettings else { return }
        self.size = settings.size
        self.color = settings.color
        self.encoding = settings.encoding
        self.language = settings.language
        self.font = settings.font
        self.style = settings.style
    }
    
    func save() {
        UserDefaults.standard.set(NSKeyedArchiver.archivedData(withRootObject: self), forKey: "subtitleSettings")
        UserDefaults.standard.synchronize()
    }
    
    required init?(coder aDecoder: NSCoder) {
        guard let color = aDecoder.decodeObject(of: UIColor.self, forKey: "color"),
            let size = aDecoder.decodeObject(forKey: "size") as? CGFloat,
            let encoding = aDecoder.decodeObject(of: NSString.self, forKey: "encoding") as? String,
            let descriptor = aDecoder.decodeObject(of: UIFontDescriptor.self, forKey: "font"),
            let rawValue = aDecoder.decodeObject(of: NSString.self, forKey: "style") as? String,
            let style = UIFont.FontStyle(rawValue: rawValue) else { return nil }
        self.size = Float(size)
        self.color = color
        self.encoding = encoding
        self.language = aDecoder.decodeObject(of: NSString.self, forKey: "language") as? String
        self.font = UIFont(descriptor: descriptor, size: 16)
        self.style = style
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(CGFloat(size), forKey: "size")
        aCoder.encode(color, forKey: "color")
        aCoder.encode(encoding, forKey: "encoding")
        aCoder.encode(language, forKey: "language")
        aCoder.encode(font.fontDescriptor, forKey: "font")
        aCoder.encode(style.rawValue, forKey: "style")
    }
}
