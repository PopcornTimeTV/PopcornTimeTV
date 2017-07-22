

import Foundation

struct MPMediaType: OptionSet {
    let rawValue: UInt

    static let movie   = MPMediaType(rawValue: 1 << 8)
    static let tvShow  = MPMediaType(rawValue: 1 << 9)
    static let episode = MPMediaType(rawValue: 1 << 14)
    
    static let any: MPMediaType = [.movie, .tvShow, .episode]
}
