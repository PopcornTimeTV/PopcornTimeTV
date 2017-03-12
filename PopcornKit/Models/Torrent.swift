

import Foundation
import ObjectMapper

/**
 Health of a torrent.
 */
public enum Health {
    /// Low number of seeds and peers.
    case bad
    /// Moderate number of seeds and peers.
    case medium
    /// Lots of seeds and peers.
    case good
    /// Fucking lots of seeds and peers.
    case excellent
    /// Health of the torrent cannot be calcualted.
    case unknown
    
    /**
     - Bad:         Red.
     - Medium:      Orange.
     - Good:        Yellow-green.
     - Excellent:   Bright green.
     - Unknown:     Grey.
     */
    public var color: UIColor {
        switch self {
        case .bad:
            return UIColor(red: 212.0/255.0, green: 14.0/255.0, blue: 0.0, alpha: 1.0)
        case .medium:
            return UIColor(red: 212.0/255.0, green: 120.0/255.0, blue: 0.0, alpha: 1.0)
        case .good:
            return UIColor(red: 201.0/255.0, green: 212.0/255.0, blue: 0.0, alpha: 1.0)
        case .excellent:
            return UIColor(red: 90.0/255.0, green: 186.0/255.0, blue: 0.0, alpha: 1.0)
        case .unknown:
            return UIColor(red: 105.0/255.0, green: 105.0/255.0, blue: 105.0, alpha: 1.0)
        }
    }
}

let trackers = [
    "udp://tracker.opentrackr.org:1337/announce",
    "udp://glotorrents.pw:6969/announce",
    "udp://torrent.gresille.org:80/announce",
    "udp://tracker.openbittorrent.com:80",
    "udp://tracker.coppersurfer.tk:6969",
    "udp://tracker.leechers-paradise.org:6969",
    "udp://p4p.arenabg.ch:1337",
    "udp://tracker.internetwarriors.net:1337",
    "udp://open.demonii.com:80",
    "udp://tracker.coppersurfer.tk:80",
    "udp://tracker.leechers-paradise.org:6969",
    "udp://exodus.desync.com:6969"
]

public struct Torrent: Mappable, Equatable, Comparable {
    
    /// Magnet link of the torrent. May be `nil` if the url recieved from popcorn-api points directly to a .torrent file to be downloaded.
    public var magnet: String? {
        if let hash = hash {
            return "magnet:?xt=urn:btih:\(hash)&tr=" + trackers.joined(separator: "&tr=")
        }
        return nil
    }
    
    /// Health of the torrent.
    public var health: Health
    
    /// Url of the torrent. May be http url or may be a magnet link.
    public let url: String
    
    /// Torrent hash if url is magnet link otherwise `nil`.
    public let hash: String?
    
    /// Quality of the media - 1080p, 720p, 480p etc.
    public var quality: String!
    
    /// Number of seeds the torrent has.
    public let seeds: Int
    
    /// Number of peers the torrent has.
    public let peers: Int
    
    /// Size of the torrent. Will be `nil` if object is episode.
    public let size: String?
    
    public init?(map: Map) {
        do { self = try Torrent(map) }
        catch { return nil }
    }
    
    private init(_ map: Map) throws {
        self.url = try map.value("url")
        self.hash = url.contains("https://") ? nil : url.slice(from: "magnet:?xt=urn:btih:", to: url.contains("&dn=") ? "&dn=" : "")
        self.seeds = (try? (try? map.value("seeds")) ?? map.value(("seed"))) ?? 0
        self.peers = (try? (try? map.value("peers")) ?? map.value(("peer"))) ?? 0
        self.size = try? map.value("filesize")
        self.quality = try? map.value("quality") // Will only not be `nil` if object is mapped from JSON array, otherwise this is set in `Show or Movie` struct.
        
        // First calculate the seed/peer ratio
        let ratio = peers > 0 ? (seeds / peers) : seeds
        
        // Normalize the data. Convert each to a percentage
        // Ratio: Anything above a ratio of 5 is good
        let normalizedRatio = min(ratio / 5 * 100, 100)
        // Seeds: Anything above 30 seeds is good
        let normalizedSeeds = min(seeds / 30 * 100, 100)
        
        // Weight the above metrics differently
        // Ratio is weighted 60% whilst seeders is 40%
        let weightedRatio = Double(normalizedRatio) * 0.6
        let weightedSeeds = Double(normalizedSeeds) * 0.4
        let weightedTotal = weightedRatio + weightedSeeds
        
        // Scale from [0, 100] to [0, 3]. Drops the decimal places
        var scaledTotal = ((weightedTotal * 3.0) / 100.0)// | 0.0
        if scaledTotal < 0 { scaledTotal = 0 }
        
        switch floor(scaledTotal) {
        case 0:
            health = .bad
        case 1:
            health = .medium
        case 2:
            health = .good
        case 3:
            health = .excellent
        default:
            health = .unknown
        }
    }
    
    public init(health: Health = .unknown, url: String = "", hash: String? = nil, quality: String = "0p", seeds: Int = 0, peers: Int = 0, size: String? = nil) {
        self.health = health
        self.url = url
        self.hash = hash
        self.quality = quality
        self.seeds = seeds
        self.peers = peers
        self.size = size
    }
    
    public mutating func mapping(map: Map) {
        switch map.mappingType {
        case .fromJSON:
            if let torrent = Torrent(map: map) {
                self = torrent
            }
            
        case .toJSON:
            url >>> map["url"]
            seeds >>> map["seeds"]
            peers >>> map["peers"]
            quality >>> map["quality"]
            size >>> map["filesize"]
        }
    }
}

public func >(lhs: Torrent, rhs: Torrent) -> Bool {
    if let lhsSize = lhs.quality, let rhsSize = rhs.quality {
        if lhsSize.characters.count == 2  && rhsSize.characters.count > 2 // 3D
        {
            return true
        } else if lhsSize.characters.count == 5 && rhsSize.characters.count < 5 && rhsSize.characters.count > 2 // 1080p
        {
            return true
        } else if lhsSize.characters.count == 4 && rhsSize.characters.count == 4 // 720p and 480p
        {
            return lhsSize > rhsSize
        }
    }
    return false
}

public func <(lhs: Torrent, rhs: Torrent) -> Bool {
    if let lhsSize = lhs.quality, let rhsSize = rhs.quality {
        if rhsSize.characters.count == 2  && lhsSize.characters.count > 2 // 3D
        {
            return true
        } else if rhsSize.characters.count == 5 && lhsSize.characters.count < 5 && lhsSize.characters.count > 2 // 1080p
        {
            return true
        } else if rhsSize.characters.count == 4 && lhsSize.characters.count == 4 // 720p and 480p
        {
            return lhsSize < rhsSize
        }
    }
    return false
}

public func == (lhs: Torrent, rhs: Torrent) -> Bool {
    return lhs.hash == rhs.hash
}
