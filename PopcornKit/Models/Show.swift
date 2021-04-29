

import Foundation
import ObjectMapper
import MediaPlayer.MPMediaItem

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
    public let year: Int
    
    /// Rating percentage of the show.
    public let rating: Double
    
    /// Summary of the show. Will default to "No summary available.".localized until `getInfo:imdbId:completion` is called on `ShowManager` and shows are updated. **However**, there may not be a summary provided by the api.
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
        return largeBackgroundImage?.replacingOccurrences(of: amazonUrl ? "SX1920" : "original", with: amazonUrl ? "SX650" : "w500")
    }
    
    /// If fanart image is available, it is returned with size 1280*720.
    public var mediumBackgroundImage: String? {
        let amazonUrl = largeBackgroundImage?.isAmazonUrl ?? false
        return largeBackgroundImage?.replacingOccurrences(of: amazonUrl ? "SX1920" : "original", with: amazonUrl ? "SX1280" : "w1280")
    }
    
    /// If fanart image is available, it is returned with size 1920*1080.
    public var largeBackgroundImage: String?
    
    /// If poster image is available, it is returned with size 450*300.
    public var smallCoverImage: String? {
        let amazonUrl = largeCoverImage?.isAmazonUrl ?? false
        return largeCoverImage?.replacingOccurrences(of: amazonUrl ? "SX1000" : "w780", with: amazonUrl ? "SX300" : "w342")
    }
    
    /// If poster image is available, it is returned with size 975*650.
    public var mediumCoverImage: String? {
        let amazonUrl = largeCoverImage?.isAmazonUrl ?? false
        return largeCoverImage?.replacingOccurrences(of: amazonUrl ? "SX1000" : "w780", with: amazonUrl ? "SX650" : "w500")
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
            self.year = try map.value("year")
            self.airDay = try? map.value("airs.day")
            self.airTime = try? map.value("airs.time")
            self.rating = try map.value("rating")
        } else {
            self.id = try (try? map.value("imdb")) ?? map.value("id")
            self.tvdbId = ""//try map.value("id")
            self.year = try map.value("year")
            self.rating = try map.value("rating")
            self.largeCoverImage = try? map.value("poster_big"); largeCoverImage = largeCoverImage?.replacingOccurrences(of: "w500", with: "w780").replacingOccurrences(of: "SX300", with: "SX1000")
            self.largeBackgroundImage = try? map.value("poster_big"); largeBackgroundImage = largeBackgroundImage?.replacingOccurrences(of: "w500", with: "original").replacingOccurrences(of: "SX300", with: "SX1920")
            self.slug = try map.value("description")
            self.airDay = nil//try? map.value("air_day")
            self.airTime = nil//try? map.value("air_time")
        }
        self.summary = ((try? map.value("synopsis")) ?? (try? map.value("overview")) ?? "No summary available.".localized).removingHtmlEncoding
        var title: String = try map.value("title")
        title.removeHtmlEncoding()
        self.title = title
        self.status = try? map.value("status")
        self.runtime = (try? map.value("runtime", using: IntTransform())) ?? map.JSON["runtime"] as? Int
        self.genres = (try? map.value("genres")) ?? []
        self.episodes = (try? map.value("episodes") as [Episode]) ?? []
        self.tmdbId = try? map.value("ids.tmdb")
        self.network = try? map.value("network")
        
        var episodes = [Episode]()
        for var episode in self.episodes {
            episode.show = self
            episodes.append(episode)
        }
        self.episodes = episodes
        self.episodes.sort(by: { $0.episode < $1.episode })
        print("Show \(self.title) init'd with \(episodes.count) episodes")
    }
    
    public init(title: String = "Unknown".localized, id: String = "tt0000000", tmdbId: Int? = nil, slug: String = "unknown", summary: String = "No summary available.".localized, torrents: [Torrent] = [], subtitles: [Subtitle] = [], largeBackgroundImage: String? = nil, largeCoverImage: String? = nil) {
        self.title = title
        self.id = id
        self.tmdbId = tmdbId
        self.slug = slug
        self.summary = summary
        self.largeBackgroundImage = largeBackgroundImage
        self.largeCoverImage = largeCoverImage
        self.year = 0
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
    
    public var mediaItemDictionary: [String: Any] {
        return [MPMediaItemPropertyTitle: title,
                MPMediaItemPropertyMediaType: NSNumber(value: MPMediaType.tvShow.rawValue),
                MPMediaItemPropertyPersistentID: id,
                MPMediaItemPropertyArtwork: smallCoverImage ?? "",
                MPMediaItemPropertyBackgroundArtwork: smallBackgroundImage ?? "",
                MPMediaItemPropertySummary: summary]
    }
    
    public init?(_ mediaItemDictionary: [String: Any]) {
        guard
            let rawValue = mediaItemDictionary[MPMediaItemPropertyMediaType] as? NSNumber,
            let type = MPMediaType(rawValue: rawValue.uintValue) as MPMediaType?,
            type == MPMediaType.tvShow,
            let id = mediaItemDictionary[MPMediaItemPropertyPersistentID] as? String,
            let title = mediaItemDictionary[MPMediaItemPropertyTitle] as? String,
            let image = mediaItemDictionary[MPMediaItemPropertyArtwork] as? String,
            let backgroundImage = mediaItemDictionary[MPMediaItemPropertyBackgroundArtwork] as? String,
            let summary = mediaItemDictionary[MPMediaItemPropertySummary] as? String
            else {
                return nil
        }
        
        let largeBackgroundImage = backgroundImage.replacingOccurrences(of: backgroundImage.isAmazonUrl ? "SX300" : "w342", with: backgroundImage.isAmazonUrl ? "SX1000" : "w780")
        let largeCoverImage = image.replacingOccurrences(of: image.isAmazonUrl ? "SX300" : "w342", with: image.isAmazonUrl ? "SX1000" : "w780")
        
        self.init(title: title, id: id, slug: title.slugged, summary: summary, largeBackgroundImage: largeBackgroundImage, largeCoverImage: largeCoverImage)
    }
}

// MARK: - Hashable

extension Show: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id.hashValue)
    }
}

// MARK: Equatable

public func ==(lhs: Show, rhs: Show) -> Bool {
    return lhs.id == rhs.id
}
