

import Foundation
import UIKit

class SubtitleSettings: NSObject, NSCoding {
    
    var fontSize: Float = 16.0
    var fontColor: UIColor = .white
    var encoding: String = "Windows-1252"
    var language: String? = nil
    
    override init() {
        guard let codedData = UserDefaults.standard.data(forKey: "subtitleSettings"), let settings = NSKeyedUnarchiver.unarchiveObject(with: codedData) as? SubtitleSettings else { return }
        self.fontSize = settings.fontSize
        self.fontColor = settings.fontColor
        self.encoding = settings.encoding
        self.language = settings.language
    }
    
    func save() {
        UserDefaults.standard.set(NSKeyedArchiver.archivedData(withRootObject: self), forKey: "subtitleSettings")
        UserDefaults.standard.synchronize()
    }
    
    required init?(coder aDecoder: NSCoder) {
        guard let color = aDecoder.decodeObject(of: UIColor.self, forKey: "fontColor"),
            let size = aDecoder.decodeObject(forKey: "fontSize") as? CGFloat,
            let encoding = aDecoder.decodeObject(of: NSString.self, forKey: "encoding") as? String,
            let language = aDecoder.decodeObject(of: NSString.self, forKey: "language") as? String else { return nil }
        self.fontSize = Float(size)
        self.fontColor = color
        self.encoding = encoding
        self.language = language
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(CGFloat(fontSize), forKey: "fontSize")
        aCoder.encode(fontColor, forKey: "fontColor")
        aCoder.encode(encoding, forKey: "encoding")
        aCoder.encode(language, forKey: "language")
    }
    
    
    override var description: String {
        return "<\(type(of: self)) size: \(fontSize) color: \(fontColor)>"
    }
    
}
