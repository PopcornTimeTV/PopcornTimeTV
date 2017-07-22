

import Foundation
import ObjectMapper

private struct Static {
    static var movieInstance: WatchlistManager<Movie>? = nil
    static var showInstance: WatchlistManager<Show>? = nil
}

typealias jsonArray = [[String : Any]]

/// Class for managing a users watchlist.
open class WatchlistManager<N: Media> {
    
    private let currentType: Trakt.MediaType
    
    /// Creates new instance of WatchlistManager class with type of Shows.
    public class var show: WatchlistManager<Show> {
        DispatchQueue.once(token: "ShowWatchlist") {
            Static.showInstance = WatchlistManager<Show>()
        }
        return Static.showInstance!
    }
    
    /// Creates new instance of WatchlistManager class with type of Movies.
    public class var movie: WatchlistManager<Movie> {
        DispatchQueue.once(token: "MovieWatchlist") {
            Static.movieInstance = WatchlistManager<Movie>()
        }
        return Static.movieInstance!
    }
    
    private init?() {
        switch N.self {
        case is Movie.Type:
            currentType = .movies
        case is Show.Type:
            currentType = .shows
        default:
            return nil
        }
    }
    
    /**
     Toggles media in users watchlist and syncs with Trakt if available.
     
     - Parameter media: The media to add or remove.
     */
    open func toggle(_ media: N) {
        isAdded(media) ? remove(media): add(media)
    }
    
    /**
     Adds media to users watchlist and syncs with Trakt if available.
     
     - Parameter media: The media to add.
     */
    open func add(_ media: N) {
        TraktManager.shared.add(media.id, toWatchlistOfType: currentType)
        var array = UserDefaults.standard.object(forKey: "\(currentType.rawValue)Watchlist") as? jsonArray ?? jsonArray()
        array.append(Mapper<N>().toJSON(media))
        UserDefaults.standard.set(array, forKey: "\(currentType.rawValue)Watchlist")
    }
    
    /**
     Removes media from users watchlist and syncs with Trakt if available.
     
     - Parameter media: The media to remove.
     */
    open func remove(_ media: N) {
        TraktManager.shared.remove(media.id, fromWatchlistOfType: currentType)
        if var array = UserDefaults.standard.object(forKey: "\(currentType.rawValue)Watchlist") as? jsonArray,
            let index = Mapper<N>().mapArray(JSONArray: array).index(where: { $0.id == media.id }) {
            array.remove(at: index)
            UserDefaults.standard.set(array, forKey: "\(currentType.rawValue)Watchlist")
        }
    }
    
    /**
     Checks media is in the watchlist.
     
     - Parameter media: The media.
     
     - Returns: Boolean indicating if media is in the users watchlist.
     */
    open func isAdded(_ media: N) -> Bool {
        if let array = UserDefaults.standard.object(forKey: "\(currentType.rawValue)Watchlist") as? jsonArray {
            return Mapper<N>().mapArray(JSONArray: array).contains(where: {$0.id == media.id})
        }
        return false
    }
    
    /**
     Gets watchlist locally first and then from Trakt if available.
     
     - Parameter completion: If Trakt is available, completion will be called with a more up-to-date watchlist that will replace the locally stored one and should be reloaded for the user.
     
     - Returns: Locally stored watchlist (may be out of date if user has authenticated with trakt).
     */
    @discardableResult open func getWatchlist(_ completion: (([N]) -> Void)? = nil) -> [N] {
        let array = UserDefaults.standard.object(forKey: "\(currentType.rawValue)Watchlist") as? jsonArray ?? jsonArray()
        
        TraktManager.shared.getWatchlist(forMediaOfType: N.self) { [unowned self] (medias, error) in
            guard error == nil else {return}
            UserDefaults.standard.set(Mapper<N>().toJSONArray(medias), forKey: "\(self.currentType.rawValue)Watchlist")
            completion?(medias)
        }
        
        return Mapper<N>().mapArray(JSONArray: array)
    }
}
