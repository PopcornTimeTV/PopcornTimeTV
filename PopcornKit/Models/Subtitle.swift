

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
    
    /// Two letter ISO language code of the subtitle eg. en.
    public let ISO639: String
    
    /// The OpenSubtitles rating for the subtitle.
    internal let rating: Double
    
    /// The OpenSubtitles hash for the subtitle.
    internal var movieHash: OpenSubtitlesHash.VideoHash?
    
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
