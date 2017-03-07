

import Foundation
import ObjectMapper

/**
 Struct for managing show objects. 
 
 **Important:** In the description of all the optional variables where it says another method must be called on **only** `ShowManager` to populate `x`, does not apply if the show was loaded from Trakt. **However** episodes array will be empty for both Trakt and popcorn-api show objects.
 
 `TraktManager` has to be called regardless to fill up the special variables.
 */
public struct Show: Media, Equatable {
    
    /// Imdb id of show.
    public var id: String

    /// TMDB id of the show. This will be `nil` unless explicitly set by calling `getTMDBId:forImdbId:completion:` on `TraktManager` or the show was loaded from Trakt.
    public var tmdbId: Int?
    
    /// Tvdb for show.
    public var tvdbId: String
    
    /// Slug of the show.
    public let slug: String
    
    /// Title of the show.
    public let title: String
    
    /// Release date of the show.
    public let year: String
    
    /// Rating percentage of the show.
    public let rating: Float
    
    /// Summary of the show. Will default to "No summary available." until `getInfo:imdbId:completion` is called on `ShowManager` and shows are updated. **However**, there may not be a summary provided by the api.
    public let summary: String
    
    /// Network that the show is officially released on. Will be `nil` until `getInfo:imdbId:completion` is called on `ShowManager` and shows are updated.
    public var network: String?
    
    /// Air day of the show. Will be `nil` until `getInfo:imdbId:completion` is called on `ShowManager` and shows are updated.
    public var airDay: String?
    
    /// Air time of the show. Will be `nil` until `getInfo:imdbId:completion` is called on `ShowManager` and shows are updated.
    public var airTime: String?
    
    /// Average runtime of each episode of the show rounded to the nearest minute. Will be `nil` until `getInfo:imdbId:completion` is called on `ShowManager` and shows are updated.
    public var runtime: Int?
    
    /// Status of the show. ie. Returning series, Ended etc. Will be `nil` until `getInfo:imdbId:completion` is called on `ShowManager` and shows are updated.
    public var status: String?
    
    /// The season numbers of the available seasons. The popcorn-api may only retrieve some seasons in arbitrary order. This variable contains the sorted season numbers. For example, popcorn-api only fetches series 21-28 of The Simpsons. This array will contain the numbers 21, 22, 23 ... 28 sorted by lowest first.
    public var seasonNumbers: [Int] {
        return Array(Set(episodes.map({$0.season}))).sorted()
    }
    
    /// If fanart image is available, it is returned with size 650*366.
    public var smallBackgroundImage: String? {
        let amazonUrl = largeBackgroundImage?.isAmazonUrl ?? false
        return largeBackgroundImage?.replacingOccurrences(of: amazonUrl ? "SX1920" : "w1920", with: amazonUrl ? "SX650" : "w650")
    }
    
    /// If fanart image is available, it is returned with size 1280*720.
    public var mediumBackgroundImage: String? {
        let amazonUrl = largeBackgroundImage?.isAmazonUrl ?? false
        return largeBackgroundImage?.replacingOccurrences(of: amazonUrl ? "SX1920" : "w1920", with: amazonUrl ? "SX1280" : "w1280")
    }
    
    /// If fanart image is available, it is returned with size 1920*1080.
    public var largeBackgroundImage: String?
    
    /// If poster image is available, it is returned with size 450*300.
    public var smallCoverImage: String? {
        let amazonUrl = largeCoverImage?.isAmazonUrl ?? false
        return largeCoverImage?.replacingOccurrences(of: amazonUrl ? "SX1000" : "w1000", with: amazonUrl ? "SX300" : "w300")
    }
    
    /// If poster image is available, it is returned with size 975*650.
    public var mediumCoverImage: String? {
        let amazonUrl = largeCoverImage?.isAmazonUrl ?? false
        return largeCoverImage?.replacingOccurrences(of: amazonUrl ? "SX1000" : "w1000", with: amazonUrl ? "SX650" : "w650")
    }
    
    /// If poster image is available, it is returned with size 1500*1000
    public var largeCoverImage: String?
    
    
    /// Convenience variable. Boolean value indicating whether or not the show has been added the users watchlist.
    public var isAddedToWatchlist: Bool {
        get {
            return WatchlistManager<Show>.show.isAdded(self)
        } set (add) {
            add ? WatchlistManager<Show>.show.add(self) : WatchlistManager<Show>.show.remove(self)
        }
    }
    
    
    /// All the people that worked on the show. Empty by default. Must be filled by calling `getPeople:forMediaOfType:id:completion` on `TraktManager`.
    public var crew = [Crew]()
    
    /// All the actors in the show. Empty by default. Must be filled by calling `getPeople:forMediaOfType:id:completion` on `TraktManager`.
    public var actors = [Actor]()
    
    /// The related shows. Empty by default. Must be filled by calling `getRelated:media:completion` on `TraktManager`.
    public var related = [Show]()
    
    /// All the episodes in the show sorted by season number. Empty by default. Must be filled by calling `getInfo:imdbId:completion` on `ShowManager`.
    public var episodes = [Episode]()
    
    /// The genres associated with the show. Empty by default. Must be filled by calling `getInfo:imdbId:completion` on `ShowManager`.
    public var genres = [String]()
    
    public init?(map: Map) {
        do { self = try Show(map) }
        catch { return nil }
    }
    
    private init(_ map: Map) throws {
        if map.context is TraktContext {
            self.id = try map.value("ids.imdb")
            self.tvdbId = try map.value("ids.tvdb", using: StringTransform())
            self.slug = try map.value("ids.slug")
            self.year = try map.value("year", using: StringTransform())
            self.airDay = try? map.value("airs.day")
            self.airTime = try? map.value("airs.time")
            self.rating = try map.value("rating")
        } else {
            self.id = try (try? map.value("imdb_id")) ?? map.value("_id")
            self.tvdbId = try map.value("tvdb_id")
            self.year = try map.value("year")
            self.rating = try map.value("rating.percentage")
            self.largeCoverImage = try? map.value("images.poster"); largeCoverImage = largeCoverImage?.replacingOccurrences(of: "w500", with: "w1000").replacingOccurrences(of: "SX300", with: "SX1000")
            self.largeBackgroundImage = try? map.value("images.fanart"); largeBackgroundImage = largeBackgroundImage?.replacingOccurrences(of: "w500", with: "w1920").replacingOccurrences(of: "SX300", with: "SX1920")
            self.slug = try map.value("slug")
            self.airDay = try? map.value("air_day")
            self.airTime = try? map.value("air_time")
        }
        self.summary = (try? map.value("synopsis")) ?? "No summary available."
        self.title = try map.value("title")
        self.status = try? map.value("status")
        self.runtime = try? map.value("runtime", using: IntTransform())
        self.genres = (try? map.value("genres")) ?? []
        self.episodes = (try? map.value("episodes")) ?? []
        self.tmdbId = try? map.value("ids.tmdb")
        self.network = try? map.value("network")
        
        var episodes = [Episode]()
        for var episode in self.episodes {
            episode.show = self
            episodes.append(episode)
        }
        self.episodes = episodes
        self.episodes.sort(by: { $0.episode < $1.episode })
    }
    
    public init(title: String = "Unknown", id: String = "tt0000000", tmdbId: Int? = nil, slug: String = "unknown", summary: String = "No summary available.", torrents: [Torrent] = [], subtitles: [Subtitle] = [], largeBackgroundImage: String? = nil, largeCoverImage: String? = nil) {
        self.title = title
        self.id = id
        self.tmdbId = tmdbId
        self.slug = slug
        self.summary = summary
        self.largeBackgroundImage = largeBackgroundImage
        self.largeCoverImage = largeCoverImage
        self.year = "Unknown"
        self.rating = 0.0
        self.runtime = 0
        self.tvdbId = "0000000"
    }
    
    public mutating func mapping(map: Map) {
        switch map.mappingType {
        case .fromJSON:
            if let show = Show(map: map) {
                self = show
            }
        case .toJSON:
            id >>> map["imdb_id"]
            tmdbId >>> map["ids.tmdb"]
            tvdbId >>> map["tvdb_id"]
            slug >>> map["slug"]
            year >>> map["year"]
            rating >>> map["rating.percentage"]
            largeCoverImage >>> map["images.poster"]
            largeBackgroundImage >>> map["images.fanart"]
            title >>> map["title"]
            runtime >>> (map["runtime"], IntTransform())
            summary >>> map["synopsis"]
            genres >>> map["genres"]
            status >>> map["status"]
            airDay >>> map["air_day"]
            airTime >>> map["air_time"]
        }
    }
}

// MARK: - Hashable

extension Show: Hashable {
    public var hashValue: Int {
        return id.hashValue
    }
}

// MARK: Equatable

public func ==(lhs: Show, rhs: Show) -> Bool {
    return lhs.id == rhs.id
}
