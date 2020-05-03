

import Foundation
import UIKit

class SubtitleSettings: NSObject, NSCoding {
    
    enum Size: Float {
        case small = 20.0
        case medium = 16.0
        case mediumLarge = 12.0
        case large = 6.0
        
        static let array = [small, medium, mediumLarge, large]
        
        var localizedString: String {
            switch self {
            case .small:
                return "Small".localized
            case .medium:
                return "Medium".localized
            case .mediumLarge:
                return "Medium Large".localized
            case .large:
                return "Large".localized
            }
        }
    }
    
    static var encodings: [String: String] {
        return [
            "Universal (UTF-8)": "UTF-8",
            "Universal (UTF-16)": "UTF-16",
            "Universal (big endian UTF-16)": "UTF-16BE",
            "Universal (little endian UTF-16)": "UTF-16LE",
            "Universal Chinese (GB18030)": "GB18030",
            "Western European (Latin-1)": "ISO-8859-1",
            "Western European (Latin-9)": "ISO-8859-15",
            "Western European (Windows-1252)": "Windows-1252",
            "Western European (IBM 00850)": "IBM850",
            "Eastern European (Latin-2)": "ISO-8859-2",
            "Eastern European (Windows-1250)": "Windows-1250",
            "Esperanto (Latin-3)": "ISO-8859-3",
            "Nordic (Latin-6)": "ISO-8859-10",
            "Cyrillic (Windows-1251)": "Windows-1251",
            "Russian (KOI8-R)": "KOI8-R",
            "Ukrainian (KOI8-U)": "KOI8-U",
            "Arabic (ISO 8859-6)": "ISO-8859-6",
            "Arabic (Windows-1256)": "Windows-1256",
            "Greek (ISO 8859-7)": "ISO-8859-7",
            "Greek (Windows-1253)": "Windows-1253",
            "Hebrew (ISO 8859-8)": "ISO-8859-8",
            "Hebrew (Windows-1255)": "Windows-1255",
            "Turkish (ISO 8859-9)": "ISO-8859-9",
            "Turkish (Windows-1254)": "Windows-1254",
            "Thai (TIS 620-2533/ISO 8859-11)": "ISO-8859-11",
            "Thai (Windows-874)": "Windows-874",
            "Baltic (Latin-7)": "ISO-8859-13",
            "Baltic (Windows-1257)": "Windows-1257",
            "Celtic (Latin-8)": "ISO-8859-14",
            "South-Eastern European (Latin-10)": "ISO-8859-16",
            "Simplified Chinese (ISO-2022-CN-EXT)": "ISO-2022-CN-EXT",
            "Simplified Chinese Unix (EUC-CN)": "EUC-CN",
            "Japanese (7-bits JIS/ISO-2022-JP-2)": "ISO-2022-JP-2",
            "Japanese Unix (EUC-JP)": "EUC-JP",
            "Japanese (Shift JIS)": "Shift_JIS",
            "Korean (EUC-KR/CP949)": "CP949",
            "Korean (ISO-2022-KR)": "ISO-2022-KR",
            "Traditional Chinese (Big5)": "Big5",
            "Traditional Chinese Unix (EUC-TW)": "ISO-2022-TW",
            "Hong-Kong Supplementary (HKSCS)": "Big5-HKSCS",
            "Vietnamese (VISCII)": "VISCII",
            "Vietnamese (Windows-1258)": "Windows-1258"
        ]
    }
    
    var size: Size = .medium
    var color: UIColor = .white
    var encoding: String = "UTF-8"
    var language: String? = nil
    var font: UIFont = UIFont.systemFont(ofSize: CGFloat(Size.medium.rawValue))
    var style: UIFont.Style = .normal
    var subtitlesSelectedForVideo: [Any] = Array()
    
    static let shared = SubtitleSettings()
    
    override init() {
        
        
        do {
            guard let codedData = UserDefaults.standard.data(forKey: "subtitleSettings"), let settings = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(codedData) as? SubtitleSettings else { return }
            self.size = settings.size
            self.color = settings.color
            self.encoding = settings.encoding
            self.language = settings.language
            self.font = settings.font
            self.style = settings.style
        }
        catch {
            print("try error")
        }
        
    }
    
    func save() {
        subtitlesSelectedForVideo.removeAll()
        do {
            UserDefaults.standard.set(try NSKeyedArchiver.archivedData(withRootObject: self, requiringSecureCoding: false), forKey: "subtitleSettings")
        }
        catch {
            print("try error")
        }
        
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
