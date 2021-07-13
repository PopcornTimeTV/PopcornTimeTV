import Foundation

class ShowCache: NSObject {

    /// Creates new instance of ShowManager class
    public var allShows: Array<Show> = []

    func show(_ imdbId: String) -> Show? {
        return allShows.filter{ $0.id == imdbId }.first
    }

    func addShow(_ show: Show) {
        allShows.append(show)
    }

    func addShows(_ shows: [Show]) {
        allShows.append(contentsOf: shows)
    }
}
