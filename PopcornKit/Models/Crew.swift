

import Foundation
import ObjectMapper

/**
 Struct for managing crew objects.
 */
public struct Crew: Person, Equatable {
    
    /// Name of the person.
    public let name: String
    /// Their job on set.
    public let job: String
    /// The group they were part of.
    public var roleType: Role
    /// Imdb id of the person.
    public let imdbId: String
    /// TMDB id of the person.
    public let tmdbId: Int
    
    /// If headshot image is available, it is returned with size 1000*1500.
    public var largeImage: String?
    /// If headshot image is available, it is returned with size 600*900.
    public var mediumImage: String? {
        return largeImage?.replacingOccurrences(of: "original", with: "w500")
    }
    /// If headshot image is available, it is returned with size 300*450.
    public var smallImage: String? {
        return largeImage?.replacingOccurrences(of: "original", with: "w300")
    }
    
    
    public init?(map: Map) {
        do { self = try Crew(map) }
        catch { return nil }
    }
    
    private init(_ map: Map) throws {
        self.name = try map.value("person.name")
        self.job = (try? map.value("job")) ?? ""
        self.largeImage = try? map.value("person.images.headshot.full")
        self.imdbId = try map.value("person.ids.imdb")
        self.tmdbId = try map.value("person.ids.tmdb")
        self.roleType = (try? map.value("roleType")) ?? .unknown // Will only not be `nil` if object is mapped from JSON array, otherwise this is set in `TraktManager` object.
    }
    
    public init(name: String = "Unknown", imdbId: String = "nm0000000", tmdbId: Int = 0000000, largeImage: String? = nil) {
        self.name = name
        self.job = ""
        self.largeImage = largeImage
        self.imdbId = imdbId
        self.tmdbId = tmdbId
        self.roleType =  .unknown
    }
    
    public mutating func mapping(map: Map) {
        switch map.mappingType {
        case .fromJSON:
            if let crew = Crew(map: map) {
                self = crew
            }
        case .toJSON:
            roleType >>> map["roleType"]
            imdbId >>> map["person.ids.imdb"]
            tmdbId >>> map["person.ids.tmdb"]
            largeImage >>> map["person.images.headshot.full"]
            job >>> map["job"]
            name >>> map["person.name"]
        }
    }
    
}

// MARK: - Hashable

extension Crew: Hashable {
    public var hashValue: Int {
        return imdbId.hashValue
    }
}

// MARK: Equatable

public func ==(rhs: Crew, lhs: Crew) -> Bool {
    return rhs.imdbId == lhs.imdbId
}

public enum Role: String {
    case artist = "art"
    case cameraman = "camera"
    case designer = "costume & make-up"
    case director = "directing"
    case other = "crew"
    case producer = "production"
    case soundEngineer = "sound"
    case writer = "writing"
    case unknown = "unknown"
}
