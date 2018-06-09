

import Foundation
import ObjectMapper

/**
  Struct for managing subtitle objects.
 */
public struct Subtitle: Equatable,Mappable {
    
    /// Language string of the subtitle. Eg. English.
    public let language: String
    static let defaultLang = "Unknown"
    
    /// Link to the subtitle zip.
    public let link: String
    
    /// Two letter ISO language code of the subtitle eg. en.
    public let ISO639: String
    
    /// The OpenSubtitles rating for the subtitle.
    internal let rating: Double
    
    /// The OpenSubtitles hash for the subtitle.
    internal var movieHash: OpenSubtitlesHash.VideoHash?
    
    public init?(map: Map) {
        do { self = try Subtitle(map) }
        catch { return nil }
    }
    
    private init(_ map: Map) throws{
        let initialLink = try map.value("SubDownloadLink") ?? ""
        self.link = initialLink[initialLink.startIndex..<initialLink.range(of: "download/")!.upperBound] + "subencoding-utf8/" + initialLink[initialLink.range(of: "download/")!.upperBound...]
        let ISOname = try map.value("ISO639") ?? ""
        self.ISO639 = ISOname
        self.rating = try (map.value("SubRating") as NSString).doubleValue
        let subLanguage = (Locale.current.localizedString(forLanguageCode: ISOname)?.localizedCapitalized ??
            Locale.current.localizedString(forLanguageCode: ISOname.replacingOccurrences(of: "pob", with: "pt_BR")) ?? Locale.current.localizedString(forLanguageCode: ISOname.replacingOccurrences(of: "pb", with: "pt_BR")))
        self.language = subLanguage ?? Subtitle.defaultLang
    }
    
    public mutating func mapping(map: Map) {
        switch map.mappingType {
        case .fromJSON:
            if let subtitle =  Subtitle(map: map) {
                self = subtitle
            }
        case .toJSON:
            language >>> map["language"]
            link >>> map["link"]
            ISO639 >>> map["ISO639"]
            rating >>> map["rating"]
            movieHash >>> map["movieHash"]
        }
    }
    
    public init(language: String, link: String, ISO639: String, rating: Double, movieHash: OpenSubtitlesHash.VideoHash? = nil) {
        self.language = language
        self.movieHash = movieHash
        self.link = link
        self.ISO639 = ISO639
        self.rating = rating
    }
}



public func ==(lhs: Subtitle, rhs: Subtitle) -> Bool {
    return lhs.link == rhs.link
}
