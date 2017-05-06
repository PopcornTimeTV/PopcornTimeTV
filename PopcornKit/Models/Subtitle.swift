

import Foundation
import ObjectMapper

/**
  Struct for managing subtitle objects.
 */
public struct Subtitle: Equatable {
    /// Language string of the subtitle. Eg. English.
    public let language: String
    /// Link to the subtitle zip.
    public let link: String
    // Name of the subtitle file
    public let name: String
    // Name of the subtitle file without movie name
    public let cleanName: String
    /// Two letter ISO language code of the subtitle eg. en.
    public let ISO639: String
    
    public init(language: String, link: String, name: String, cleanName: String, ISO639: String) {
        self.language = language
        self.link = link
        self.name = name
        self.ISO639 = ISO639
        self.cleanName = cleanName
    }
    
}

public func ==(lhs: Subtitle, rhs: Subtitle) -> Bool {
    return lhs.link == rhs.link
}
