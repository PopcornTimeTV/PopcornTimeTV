

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
    
    public var image: UIImage {
        let rect = CGRect(x: 0.0, y: 0.0, width: 10.0, height: 10.0)
        UIGraphicsBeginImageContext(rect.size)

        UIBezierPath(roundedRect: rect, cornerRadius: 10.0).addClip()
        let context = UIGraphicsGetCurrentContext()
        
        context?.setFillColor(color.cgColor)
        context?.fill(rect)
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image!
    }
}

public struct Torrent: Mappable, Equatable, Comparable {
    
    /// Health of the torrent.
    public let health: Health
    
    /// Url of the torrent. May be http url or may be a magnet link.
    public let url: String
    
    /// Quality of the media - 1080p, 720p, 480p etc.
    public var quality: String!
    
    /// Number of seeds the torrent has.
    public let seeds: Int
    
    /// Number of peers the torrent has.
    public let peers: Int
    
    /// Size of the torrent. Will be `nil` if object is episode.
    public let size: Int?
    
    public init?(map: Map) {
        do { self = try Torrent(map) }
        catch { return nil }
    }
    
    enum MyError: Error {
        case runtimeError(String)
    }

    private init(_ map: Map) throws {
        let torrent: String = try map.value("torrent_url")
        let magnet: String = try map.value("torrent_magnet")
        if magnet != "" {
            self.url = magnet
        } else if torrent.prefix(2) == "//" {
            self.url = "http:\(torrent)"
        } else if torrent.prefix(4) == "http" {
            self.url = torrent
        } else {
            self.url = try map.value("fail")
        }
        self.seeds = (try? (try? map.value("torrent_seeds")) ?? map.value(("seeds"))) ?? 0
        self.peers = (try? (try? map.value("torrent_peers")) ?? map.value(("peers"))) ?? 0
        self.size = try? map.value("size_bytes")
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
    
    public init(health: Health = .unknown, url: String = "", quality: String = "0p", seeds: Int = 0, peers: Int = 0, size: Int? = nil) {
        self.health = health
        self.url = url
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
        if lhsSize.count == 2  && rhsSize.count > 2 // 3D
        {
            return true
        } else if lhsSize.count == 5 && rhsSize.count < 5 && rhsSize.count > 2 // 1080p
        {
            return true
        } else if lhsSize.count == 4 && rhsSize.count == 4 // 720p and 480p
        {
            return lhsSize > rhsSize
        }
    }
    return false
}

public func <(lhs: Torrent, rhs: Torrent) -> Bool {
    if let lhsSize = lhs.quality, let rhsSize = rhs.quality {
        if rhsSize.count == 2  && lhsSize.count > 2 // 3D
        {
            return true
        } else if rhsSize.count == 5 && lhsSize.count < 5 && lhsSize.count > 2 // 1080p
        {
            return true
        } else if rhsSize.count == 4 && lhsSize.count == 4 // 720p and 480p
        {
            return lhsSize < rhsSize
        }
    }
    return false
}

public func == (lhs: Torrent, rhs: Torrent) -> Bool {
    return lhs.url == rhs.url
}
