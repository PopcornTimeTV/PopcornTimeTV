

import Foundation
import ObjectMapper

private struct Static {
    static var episodeInstance: WatchedlistManager<Episode>? = nil
    static var movieInstance: WatchedlistManager<Movie>? = nil
}

/// Class for managing a users watch history. **Only available for movies, and episodes**.
open class WatchedlistManager<N: Media & Hashable> {
    
    private let currentType: Trakt.MediaType
    
    /// Creates new instance of WatchedlistManager class with type of Episodes.
    public class var episode: WatchedlistManager<Episode> {
        DispatchQueue.once(token: "EpisodeWatchedlist") {
            Static.episodeInstance = WatchedlistManager<Episode>()
        }
        return Static.episodeInstance!
    }
    
    /// Creates new instance of WatchlistManager class with type of Movies.
    public class var movie: WatchedlistManager<Movie> {
        DispatchQueue.once(token: "MovieWatchedlist") {
            Static.movieInstance = WatchedlistManager<Movie>()
        }
        return Static.movieInstance!
    }
    
    private init?() {
        switch N.self {
        case is Movie.Type:
            currentType = .movies
        case is Episode.Type:
            currentType = .episodes
        default:
            return nil
        }
    }
    
    /**
     Toggles a users watched status on the passed in media id and syncs with Trakt if available.
     
     - Parameter id: The imdbId for movie or tvdbId for episode.
     */
    open func toggle(_ id: String) {
        isAdded(id) ? remove(id): add(id)
    }
    
    /**
     Adds movie or episode to watchedlist and syncs with Trakt if available.
     
     - Parameter id: The imdbId or tvdbId of the movie or episode.
     */
    open func add(_ id: String) {
        TraktManager.shared.add(id, toWatchedlistOfType: currentType)
        var array = UserDefaults.standard.object(forKey: "\(currentType.rawValue)Watchedlist") as? [String] ?? [String]()
        !array.contains(id) ? array.append(id) : ()
        UserDefaults.standard.set(array, forKey: "\(currentType.rawValue)Watchedlist")
    }
    
    /**
     Removes movie or episode from a users watchedlist, sets its progress to 0.0 and syncs with Trakt if available.
     
     - Parameter id: The imdbId for movie or tvdbId for episode.
     */
    open func remove(_ id: String) {
        TraktManager.shared.remove(id, fromWatchedlistOfType: currentType)
        TraktManager.shared.scrobble(id, progress: 0, type: currentType, status: .finished)
        var array = UserDefaults.standard.object(forKey: "\(currentType.rawValue)Watchedlist") as? [String] ?? []
        var dict = UserDefaults.standard.object(forKey: "\(currentType.rawValue)Progress") as? [String: Float] ?? [:]
        if let index = array.firstIndex(of: id) {
            array.remove(at: index)
        }
        dict.removeValue(forKey: id)
        UserDefaults.standard.set(dict, forKey: "\(currentType.rawValue)Progress")
        UserDefaults.standard.set(array, forKey: "\(currentType.rawValue)Watchedlist")
        
    }
    
    /**
     Checks if movie or episode is in the watchedlist.
     
     - Parameter id: The imdbId for movie or tvdbId for episode.
     
     - Returns: Boolean indicating if movie or episode is in watchedlist.
     */
    open func isAdded(_ id: String) -> Bool {
        if let array = UserDefaults.standard.object(forKey: "\(currentType.rawValue)Watchedlist") as? [String] {
            return array.contains(id)
        }
        return false
    }
    
    /**
     Gets watchedlist locally first and then from Trakt.
     
     - Parameter completion: Called if local watchedlist was updated from trakt.
     
     - Returns: Locally stored watchedlist imdbId's (may be out of date if user has authenticated with trakt).
     */
    @discardableResult open func getWatched(completion: (([N]) -> Void)? = nil) -> [String] {
        DispatchQueue.global(qos: .background).async{
            TraktManager.shared.getWatched(forMediaOfType: N.self) { [unowned self] (medias, error) in
                guard error == nil else { return }
                
                let ids = medias.map({ $0.id })
                UserDefaults.standard.set(ids, forKey: "\(self.currentType.rawValue)Watchedlist")
                
                completion?(medias)
            }
        }
        
        let watched = UserDefaults.standard.object(forKey: "\(currentType.rawValue)Watchedlist") as? [String] ?? [String]()
        return watched
    }
    
    /**
     Stores movie progress and syncs with Trakt if available.
     
     - Parameter progress:  The progress of the playing video. Possible values range from 0...1.
     - Parameter id:        The imdbId for movies and tvdbId for episodes of the media that is playing.
     - Parameter status:    The status of the item.
     */
    open func setCurrentProgress(_ progress: Float, for id: String, with status: Trakt.WatchedStatus) {
        progress <= 0.8 ? TraktManager.shared.scrobble(id, progress: progress, type: currentType, status: status) : ()
        var dict = UserDefaults.standard.object(forKey: "\(currentType.rawValue)Progress") as? [String: Float] ?? [String: Float]()
        let _ = progress == 0 ? dict.removeValue(forKey: id) : dict.updateValue(progress, forKey: id)
        progress >= 0.8 ? add(id) : ()
        UserDefaults.standard.set(dict, forKey: "\(currentType.rawValue)Progress")
    }
    
    /**
     Retrieves latest progress from Trakt and updates local storage.
     
     - Important: Local watchedlist may be more up-to-date than Trakt version but local version will be replaced with Trakt version regardless.
     
     - Parameter completion: Optional completion handler called when progress has been retrieved from trakt. May never be called if user hasn't authenticated with Trakt.
     
     - Returns: Locally stored progress (may be out of date if user has authenticated with trakt).
     */
    @discardableResult open func getProgress(completion: (([N: Float]) -> Void)? = nil) -> [String: Float] {
        DispatchQueue.global(qos: .background).async{
            TraktManager.shared.getPlaybackProgress(forMediaOfType: N.self) { (dict, error) in
                guard error == nil else { return }
                
                let media = Array(dict.keys)
                let ids = media.map({ $0.id })
                let progress = Array(dict.values)
                
                UserDefaults.standard.set(Dictionary<String, Float>(zip(ids, progress)), forKey: "\(self.currentType.rawValue)Progress")
                
                completion?(dict)
            }
        }
        
        let progress = UserDefaults.standard.object(forKey: "\(self.currentType.rawValue)Progress") as? [String: Float] ?? [String: Float]()
        return progress
    }
    
    /**
     Gets watched progress for movie or epsiode.
     
     - Parameter id: The imdbId for movie or tvdbId for episode.
     
     - Returns: The users last play position progress from 0.0 to 1.0 (if any).
     */
    open func currentProgress(_ id: String) -> Float {
        if let dict = UserDefaults.standard.object(forKey: "\(currentType.rawValue)Progress") as? [String: Float],
            let progress = dict[id] {
            return progress
        }
        return 0.0
    }
    
    /**
     Retrieves media that the user is currently watching.
     
     - Parameter completion: Optional completion handler called when on deck media has been retrieved from trakt. May never be called if user hasn't authenticated with Trakt.
     
     - Returns: Locally stored on deck media id's (may be out of date if user has authenticated with trakt).
     */
    @discardableResult open func getOnDeck(completion: (([N]) -> Void)? = nil) -> [String] {
        let group = DispatchGroup()
        
        var updatedWatched:  [N] = []
        var updatedProgress: [N] = []
        
        group.enter()
        let watched = getWatched() { updated in
            updatedWatched = updated
            group.leave()
        }
        if !TraktManager.shared.isSignedIn(){
            group.leave()
        }
        group.enter()
        let progress = Array(getProgress() { updated in
            updatedProgress = Array(updated.keys)
            group.leave()
            }.keys)
        if !TraktManager.shared.isSignedIn(){
            group.leave()
        }
        group.notify(queue: .main) {
            completion?(Array(Set(updatedProgress).subtracting(updatedWatched)))
        }
        
        return Array(Set(progress).subtracting(watched))
    }
}
