

import Foundation
import UIKit

class SubtitleSettings: NSObject, NSCoding {
    
    enum Size: Float {
        case small = 20.0
        case medium = 16.0
        case mediumLarge = 12.0
        case large = 6.0
        
        static let array = [small, medium, mediumLarge, large]
        
        var string: String {
            switch self {
            case .small:
                return "Small"
            case .medium:
                return "Medium"
            case .mediumLarge:
                return "Medium Large"
            case .large:
                return "Large"
            }
        }
        
    }
    
    var size: Size = .medium
    var color: UIColor = .white
    var encoding: String = "Windows-1252"
    var language: String? = nil
    var font: UIFont = UIFont.systemFont(ofSize: CGFloat(Size.medium.rawValue))
    var style: UIFont.Style = .normal
    
    static let shared = SubtitleSettings()
    
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
            let rawSize = aDecoder.decodeObject(forKey: "size") as? CGFloat,
            let size = Size(rawValue: Float(rawSize)),
            let encoding = aDecoder.decodeObject(of: NSString.self, forKey: "encoding") as String?,
            let descriptor = aDecoder.decodeObject(of: UIFontDescriptor.self, forKey: "font"),
            let rawValue = aDecoder.decodeObject(of: NSString.self, forKey: "style") as String?,
            let style = UIFont.Style(rawValue: rawValue) else { return nil }
        self.size = size
        self.color = color
        self.encoding = encoding
        self.language = aDecoder.decodeObject(of: NSString.self, forKey: "language") as String?
        self.font = UIFont(descriptor: descriptor, size: CGFloat(size.rawValue))
        self.style = style
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(CGFloat(size.rawValue), forKey: "size")
        aCoder.encode(color, forKey: "color")
        aCoder.encode(encoding, forKey: "encoding")
        aCoder.encode(language, forKey: "language")
        aCoder.encode(font.fontDescriptor, forKey: "font")
        aCoder.encode(style.rawValue, forKey: "style")
    }
}
