

import Foundation
import ObjectMapper

/// Generic person protocol.
public protocol Person: Mappable {
    var name: String { get }
    var initials: String { get }
    var tmdbId: Int { get }
    var imdbId: String { get }
    var mediumImage: String? { get }
    var smallImage: String? { get }
    var largeImage: String? { get set }
    
    init(name: String, imdbId: String, tmdbId: Int, largeImage: String?)
}

extension Person {
    /// The initials of the person.
    public var initials: String {
        let parts = name.characters.split(separator: " ")
        
        guard let firstName = parts.first,
            let lastName  = parts.last,
            let firstLetter = firstName.first,
            let lastLetter = lastName.first else { return ""}
        
         return "\(firstLetter)\(lastLetter)".uppercased()
    }
}
