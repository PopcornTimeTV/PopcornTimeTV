

import ObjectMapper
import Alamofire
import SwiftyJSON

#if os(iOS)
    import SafariServices
#endif

open class TraktManager: NetworkManager {
    
    
    /// Creates new instance of TraktManager class
    open static let shared = TraktManager()
    
    /// OAuth state parameter added for extra security against cross site forgery.
    fileprivate var state: String!
    
    /// The delegate for the Trakt Authentication process.
    open weak var delegate: TraktManagerDelegate?
    
    /**
     Scrobbles current video.
     
     - Parameter id:            The imdbId for movies and tvdbId for episodes of the media that is playing.
     - Parameter progress:      The progress of the playing video. Possible values range from 0...1.
     - Parameter type:          The type of the item, either `Episode` or `Movie`.
     - Parameter status:        The status of the item.
     
     - Parameter completion:    Optional completion handler only called if an error is thrown.
     */
    open func scrobble(_ id: String, progress: Float, type: Trakt.MediaType, status: Trakt.WatchedStatus, completion: ((NSError) -> Void)? = nil) {
        guard var credential = OAuthCredential(identifier: "trakt") else { return }
        guard progress != 0 else { return removePlaybackProgress(id, type: type) }
        DispatchQueue.global(qos: .background).async {
            if credential.expired {
                do {
                    credential = try OAuthCredential(Trakt.base + Trakt.auth + Trakt.token, refreshToken: credential.refreshToken!, clientID: Trakt.apiKey, clientSecret: Trakt.apiSecret, useBasicAuthentication: false)
                } catch let error as NSError {
                    completion?(error)
                }
            }
            let parameters: [String: Any]
            if type == .movies {
                parameters = ["movie": ["ids": ["imdb": id]], "progress": progress * 100.0]
            } else {
                parameters = ["episode": ["ids": ["tvdb": Int(id)!]], "progress": progress * 100.0]
            }
            self.manager.request(Trakt.base + Trakt.scrobble + "/\(status.rawValue)", method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: Trakt.Headers.Authorization(credential.accessToken)).validate().responseJSON { response in
                if let error = response.result.error { completion?(error as NSError) }
            }
        }
    }
    
    /**
     Load episode metadata from API.
     
     - Parameter show:          The imdbId or slug for the show.
     - Parameter episodeNumber: The number of the episode in relation to its current season.
     - Parameter seasonNumber:  The season of which the episode is in.
     
     - Parameter completion:    The completion handler for the request containing an optional episode and an optional error.
     */
    open func getEpisodeMetadata(_ showId: String, episodeNumber: Int, seasonNumber: Int, completion: @escaping (Episode?, NSError?) -> Void) {
        self.manager.request(Trakt.base + Trakt.shows + "/\(showId)" + Trakt.seasons + "/\(seasonNumber)" + Trakt.episodes + "/\(episodeNumber)", parameters: Trakt.extended, headers: Trakt.Headers.Default).validate().responseJSON { response in
            guard let value = response.result.value else { completion(nil, response.result.error as NSError?); return }
            completion(Mapper<Episode>(context: TraktContext()).map(JSONObject: value), nil)
        }
    }
    
    /**
     Retrieves users previously watched videos.
     
     - Parameter type:          The type of the item (either movie or episode).
     
     - Parameter completion:    The completion handler for the request containing an array of media objects and an optional error.
     */
    open func getWatched<T: Media>(forMediaOfType type: T.Type, completion:@escaping ([T], NSError?) -> Void) {
        guard var credential = OAuthCredential(identifier: "trakt") else { return }
        DispatchQueue.global(qos: .userInitiated).async {
            if credential.expired {
                do {
                    credential = try OAuthCredential(Trakt.base + Trakt.auth + Trakt.token, refreshToken: credential.refreshToken!, clientID: Trakt.apiKey, clientSecret: Trakt.apiSecret, useBasicAuthentication: false)
                } catch let error as NSError {
                    DispatchQueue.global(qos: .background).async(execute: { completion([T](), error) })
                }
            }
            let type = type is Movie.Type ? Trakt.movies : Trakt.episodes
            let queue = DispatchQueue(label: "com.popcorntimetv.popcornkit.response.queue", attributes: .concurrent)
            self.manager.request(Trakt.base + Trakt.sync + Trakt.history + type, parameters: ["extended": "full", "limit": Int.max], headers: Trakt.Headers.Authorization(credential.accessToken)).validate().responseJSON(queue: queue, options: .allowFragments) { response in
                guard let value = response.result.value else { completion([T](), response.result.error as NSError?); return }
                let responseObject = JSON(value)
                var watchedlist = [T]()
                let group = DispatchGroup()
                for (_, item) in responseObject {
                    guard let type = item["type"].string,
                        let media = Mapper<T>(context: TraktContext()).map(JSONObject: item[type].dictionaryObject)
                        else { continue }
                    group.enter()
                    guard var episode = media as? Episode, let show = Mapper<Show>(context: TraktContext()).map(JSONObject: item["show"].dictionaryObject) else {
                        watchedlist.append(media)
                        group.leave()
                        continue
                    }
                    episode.show = show
                    watchedlist.append(episode as! T)
                    group.leave()
                }
                group.notify(queue: .main, execute: { completion(watchedlist, nil) })
            }
        }
    }
    
    /**
     Retrieves users playback progress of video if applicable.
     
     - Parameter type: The type of the item (either movie or episode).
     
     - Parameter completion: The completion handler for the request containing a dictionary of either imdbIds or tvdbIds depending on the type selected as keys and the users corrisponding watched progress as values and an optional error. Eg. ["tt1431045": 0.5] means you have watched half of Deadpool.
     */
    open func getPlaybackProgress<T: Media>(forMediaOfType type: T.Type, completion:@escaping ([T: Float], NSError?) -> Void) {
        guard var credential = OAuthCredential(identifier: "trakt") else { return }
        DispatchQueue.global(qos: .userInitiated).async {
            if credential.expired {
                do {
                    credential = try OAuthCredential(Trakt.base + Trakt.auth + Trakt.token, refreshToken: credential.refreshToken!, clientID: Trakt.apiKey, clientSecret: Trakt.apiSecret, useBasicAuthentication: false)
                } catch let error as NSError {
                    DispatchQueue.global(qos: .background).async(execute: { completion([T: Float](), error) })
                }
            }
            let mediaType: String
            switch type {
            case is Movie.Type:
                mediaType = Trakt.movies
            case is Episode.Type:
                mediaType = Trakt.episodes
            default:
                fatalError("Only retrieving progress for movies and episode is supported.")
            }
            let queue = DispatchQueue(label: "com.popcorntimetv.popcornkit.response.queue", attributes: .concurrent)
            self.manager.request(Trakt.base + Trakt.sync + Trakt.playback + mediaType, parameters: Trakt.extended, headers: Trakt.Headers.Authorization(credential.accessToken)).validate().responseJSON(queue: queue, options: .allowFragments) { response in
                guard let value = response.result.value else { completion([:], response.result.error as NSError?); return }
                let responseObject = JSON(value)
                let group = DispatchGroup()
                var progressDict = [T: Float]()
                for (_, item) in responseObject {
                    guard let type = item["type"].string,
                        let progress = item["progress"].float,
                        progress != 0,
                        let media = Mapper<T>(context: TraktContext()).map(JSONObject: item[type].dictionaryObject)
                        else { continue }
                    group.enter()
                    guard var episode = media as? Episode, let show = Mapper<Show>(context: TraktContext()).map(JSONObject: item["show"].dictionaryObject) else {
                        let completion: (Media?, NSError?) -> Void = { (media, _) in
                            if let media = media { progressDict[media as! T] = progress/100.0 }
                            group.leave()
                        }
                        media is Movie ? MovieManager.shared.getInfo(media.id, completion: completion) : ShowManager.shared.getInfo(media.id, completion: completion)
                        continue
                    }
                    episode.show = show
                    progressDict[episode as! T] = progress/100.0
                    group.leave()
                }
                group.notify(queue: .main, execute: { completion(progressDict, nil) })
            }
        }
    }
    
    /**
     `Nil`s a users playback progress of a specified media. If `id` is invalid, 404 error will be thrown.
     
     - Parameter id: The imdbId of the movie or tvdbId of the episode.
     
     - Parameter completion: An optional completion handler called only if an error is thrown.
     */
    open func removePlaybackProgress(_ id: String, type: Trakt.MediaType, completion: ((NSError) -> Void)? = nil) {
        guard var credential = OAuthCredential(identifier: "trakt") else { return }
        DispatchQueue.global(qos: .background).async {
            if credential.expired {
                do {
                    credential = try OAuthCredential(Trakt.base + Trakt.auth + Trakt.token, refreshToken: credential.refreshToken!, clientID: Trakt.apiKey, clientSecret: Trakt.apiSecret, useBasicAuthentication: false)
                } catch let error as NSError {
                    DispatchQueue.global(qos: .background).async(execute: {completion?(error) })
                }
            }
            
            self.manager.request(Trakt.base + Trakt.sync + Trakt.playback + "/\(type.rawValue)", headers: Trakt.Headers.Authorization(credential.accessToken)).validate().responseJSON { (response) in
                guard let value = response.result.value else {
                    if let error = response.result.error as NSError? {
                        completion?(error)
                    }
                    return
                }
                
                let responseObject = JSON(value)
                
                var playbackId: Int?
                
                for (_, item) in responseObject {
                    guard let t = item["type"].string,
                        let playback = item["id"].int
                        else { continue }
                    let ids = item[t]["ids"]
                    if (type == .movies && id == ids["imdb"].string) || (type == .episodes && Int(id) == ids["tvdb"].int) {
                        playbackId = playback
                        break
                    }
                }
                
                guard let id = playbackId else { return }
                
                self.manager.request(Trakt.base + Trakt.sync + Trakt.playback + "/\(id)", method: .delete, headers: Trakt.Headers.Authorization(credential.accessToken)).validate().responseJSON { response in
                    if let error = response.result.error { completion?(error as NSError) }
                }
            }
        }
    }
    
    /**
     Removes a movie or episode from a users watched history.
     
     - Parameter id:    The imdbId or tvdbId of the movie, episode or show.
     - Parameter type:  The type of the item (movie or episode).
     
     - Parameter completion:    An optional completion handler called only if an error is thrown.
     */
    open func remove(_ id: String, fromWatchedlistOfType type: Trakt.MediaType, completion: ((NSError) -> Void)? = nil) {
        guard var credential = OAuthCredential(identifier: "trakt") else { return }
        DispatchQueue.global(qos: .background).async {
            if credential.expired {
                do {
                    credential = try OAuthCredential(Trakt.base + Trakt.auth + Trakt.token, refreshToken: credential.refreshToken!, clientID: Trakt.apiKey, clientSecret: Trakt.apiSecret, useBasicAuthentication: false)
                } catch let error as NSError {
                    DispatchQueue.global(qos: .background).async(execute: {completion?(error) })
                }
            }
            let parameters: [String: Any]
            if type == .movies {
                parameters = ["movies": [["ids": ["imdb": id]]]]
            } else if type == .episodes {
                parameters = ["episodes": [["ids": ["tvdb": Int(id)!]]]]
            } else {
                parameters = [:]
            }
            self.manager.request(Trakt.base + Trakt.sync + Trakt.history + Trakt.remove, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: Trakt.Headers.Authorization(credential.accessToken)).validate().responseJSON { response in
                if let error = response.result.error { completion?(error as NSError) }
            }
        }
    }
    
    /**
     Adds specified media to users watch history.
     
     - Parameter id:    The imdbId or tvdbId of the media.
     - Parameter type:  The type of the item.
     
     - Parameter completion: The completion handler for the request containing an optional error if the request fails.
     */
    open func add(_ id: String, toWatchedlistOfType type: Trakt.MediaType, completion: ((NSError) -> Void)? = nil) {
        guard var credential = OAuthCredential(identifier: "trakt") else { return }
        DispatchQueue.global(qos: .background).async {
            if credential.expired {
                do {
                    credential = try OAuthCredential(Trakt.base + Trakt.auth + Trakt.token, refreshToken: credential.refreshToken!, clientID: Trakt.apiKey, clientSecret: Trakt.apiSecret, useBasicAuthentication: false)
                } catch let error as NSError {
                    DispatchQueue.global(qos: .background).async(execute: {completion?(error) })
                }
            }
            let parameters: [String: Any]
            if type == .movies {
                parameters = ["movies": [["ids": ["imdb": id]]]]
            } else if type == .episodes {
                parameters = ["episodes": [["ids": ["tvdb": Int(id)!]]]]
            } else {
                parameters = [:]
            }
            self.manager.request(Trakt.base + Trakt.sync + Trakt.history, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: Trakt.Headers.Authorization(credential.accessToken)).validate().responseJSON { response in
                if let error = response.result.error { completion?(error as NSError) }
            }
        }
    }
    
    /**
     Retrieves cast and crew information for a movie or show.
     
     - Parameter type:  The type of the item (movie or show).
     - Parameter id:    The id of the movie or show.
     
     - Parameter completion: The completion handler for the request containing an array of actors, array of crews and an optional error.
     */
    open func getPeople(forMediaOfType type: Trakt.MediaType, id: String, completion: @escaping ([Actor], [Crew], NSError?) -> Void) {
        self.manager.request(Trakt.base + "/\(type.rawValue)/\(id)" + Trakt.people, headers: Trakt.Headers.Default).validate().responseJSON { response in
            guard let value = response.result.value else { completion([Actor](), [Crew](), response.result.error as NSError?); return }
            let responseObject = JSON(value)
            var actors = [Actor]()
            var crew = [Crew]()
            let group = DispatchGroup()
            for (_, actor) in responseObject["cast"] {
                guard var actor = Mapper<Actor>().map(JSONObject: actor.dictionaryObject) else { continue }
                group.enter()
                TMDBManager.shared.getCharacterHeadshots(forPersonWithImdbId: actor.imdbId, orTMDBId: actor.tmdbId) { (_, image, error) in
                    if let image = image { actor.largeImage = image }
                    actors.append(actor)
                    group.leave()
                }
            }
            for (role, people) in responseObject["crew"] {
                guard let people = Mapper<Crew>().mapArray(JSONObject: people.arrayObject) else { continue }
                for var person in people {
                    group.enter()
                    TMDBManager.shared.getCharacterHeadshots(forPersonWithImdbId: person.imdbId, orTMDBId: person.tmdbId) { (_, image, error) in
                        if let image = image { person.largeImage = image }
                        person.roleType = Role(rawValue: role) ?? .unknown
                        crew.append(person)
                        group.leave()
                    }
                }
            }
            group.notify(queue: .main, execute: { completion(actors, crew, nil) })
            
        }
    }
    
    /**
     Retrieves users watchlist.
     
     - Parameter type: The type struct of the item eg. `Movie` or `Show`. Episodes not supported
     
     - Parameter completion: The completion handler for the request containing an array of media that the user has added to their watchlist and an optional error.
     */
    open func getWatchlist<T: Media>(forMediaOfType type: T.Type, completion:@escaping ([T], NSError?) -> Void) {
        guard var credential = OAuthCredential(identifier: "trakt") else { return }
        DispatchQueue.global(qos: .background).async {
            if credential.expired {
                do {
                    credential = try OAuthCredential(Trakt.base + Trakt.auth + Trakt.token, refreshToken: credential.refreshToken!, clientID: Trakt.apiKey, clientSecret: Trakt.apiSecret, useBasicAuthentication: false)
                } catch let error as NSError {
                    DispatchQueue.main.async(execute: { completion([T](), error) })
                }
            }
            let mediaType: String
            switch type {
            case is Movie.Type:
                mediaType = Trakt.movies
            case is Show.Type:
                mediaType = Trakt.shows
            default:
                mediaType = ""
            }
            let queue = DispatchQueue(label: "com.popcorntimetv.popcornkit.response.queue", attributes: .concurrent)
            self.manager.request(Trakt.base + Trakt.sync + Trakt.watchlist + mediaType, parameters: Trakt.extended, headers: Trakt.Headers.Authorization(credential.accessToken)).validate().responseJSON(queue: queue, options: .allowFragments) { response in
                guard let value = response.result.value else { completion([T](), response.result.error as NSError?); return }
                let responseObject = JSON(value)
                var watchlist = [T]()
                let group = DispatchGroup()
                for (_, item) in responseObject {
                    guard let type = item["type"].string,
                        let media = Mapper<T>(context: TraktContext()).map(JSONObject: item[type].dictionaryObject)
                        else { continue }
                    group.enter()
                    let completion: (Media?, NSError?) -> Void = { (media, _) in
                        if let media = media { watchlist.append(media as! T) }
                        group.leave()
                    }
                    media is Movie ?  MovieManager.shared.getInfo(media.id, completion: completion) : ShowManager.shared.getInfo(media.id, completion: completion)
                }
                group.notify(queue: .main, execute: { completion(watchlist, nil) })
            }
        }
    }
    
    /**
     Adds specified media to users watchlist.
     
     - Parameter id:    The imdbId or tvdbId of the media.
     - Parameter type:  The type of the item.
     
     - Parameter completion: The completion handler for the request containing an optional error if the request fails.
     */
    open func add(_ id: String, toWatchlistOfType type: Trakt.MediaType, completion: ((NSError) -> Void)? = nil) {
        guard var credential = OAuthCredential(identifier: "trakt") else { return }
        DispatchQueue.global(qos: .background).async {
            if credential.expired {
                do {
                    credential = try OAuthCredential(Trakt.base + Trakt.auth + Trakt.token, refreshToken: credential.refreshToken!, clientID: Trakt.apiKey, clientSecret: Trakt.apiSecret, useBasicAuthentication: false)
                } catch let error as NSError {
                    DispatchQueue.main.async(execute: { completion?(error) })
                }
            }
            let parameters: [String: Any]
            if type == .episodes {
                parameters = ["episodes": [["ids": ["tvdb": Int(id)!]]]]
            } else {
                parameters = [type.rawValue: [["ids": ["imdb": id]]]]
            }
            self.manager.request(Trakt.base + Trakt.sync + Trakt.watchlist, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: Trakt.Headers.Authorization(credential.accessToken)).validate().responseJSON { response in
                if let error = response.result.error { completion?(error as NSError) }
            }
        }
    }
    
    /**
     Removes specified media from users watchlist.
     
     - Parameter id:    The imdbId or tvdbId of the media.
     - Parameter type:  The type of the item.
     
     - Parameter completion: The completion handler for the request containing an optional error if the request fails.
     */
    open func remove(_ id: String, fromWatchlistOfType type: Trakt.MediaType, completion: ((NSError) -> Void)? = nil) {
        guard var credential = OAuthCredential(identifier: "trakt") else { return }
        DispatchQueue.global(qos: .background).async {
            if credential.expired {
                do {
                    credential = try OAuthCredential(Trakt.base + Trakt.auth + Trakt.token, refreshToken: credential.refreshToken!, clientID: Trakt.apiKey, clientSecret: Trakt.apiSecret, useBasicAuthentication: false)
                } catch let error as NSError {
                    DispatchQueue.main.async(execute: { completion?(error) })
                }
            }
            let parameters: [String: Any]
            if type == .episodes {
                parameters = ["episodes": [["ids": ["tvdb": Int(id)!]]]]
            } else {
                parameters = [type.rawValue: [["ids": ["imdb": id]]]]
            }
            self.manager.request(Trakt.base + Trakt.sync + Trakt.watchlist + Trakt.remove, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: Trakt.Headers.Authorization(credential.accessToken)).validate().responseJSON { response in
                if let error = response.result.error { completion?(error as NSError) }
            }
        }
    }
    
    /**
     Retrieves related media.
     
     - Parameter media: The media you would like to get more information about. **Please note:** only the imdbdId is used but an object needs to be passed in for Swift generics to work so creating a blank object with only an imdbId variable initialised will suffice if necessary.
     
     - Parameter completion: The requests completion handler containing array of related movies and an optional error.
     */
    open func getRelated<T: Media>(_ media: T, completion: @escaping ([T], NSError?) -> Void) {
        self.manager.request(Trakt.base + (media is Movie ? Trakt.movies : Trakt.shows) + "/\(media.id)" + Trakt.related, parameters: Trakt.extended, headers: Trakt.Headers.Default).validate().responseJSON { response in
            guard let value = response.result.value else { completion([T](), response.result.error as NSError?); return }
            let responseObject = JSON(value)
            let group = DispatchGroup()
            var array = [T]()
            for (_, item) in responseObject {
                guard let id = item["ids"]["imdb"].string else { continue }
                group.enter()
                let completion: (Media?, NSError?) -> Void = { (media, _) in
                    if let media = media { array.append(media as! T) }
                    group.leave()
                }
                media is Movie ?  MovieManager.shared.getInfo(id, completion: completion) : ShowManager.shared.getInfo(id, completion: completion)
            }
            group.notify(queue: .main, execute: { completion(array, nil) })
        }
    }
    
    /**
     Retrieves movies or shows that the person in cast/crew in.
     
     - Parameter id:    The id of the person you would like to get more information about.
     - Parameter type:  Just the type of the media is required for Swift generics to work.
     
     - Parameter completion:        The requests completion handler containing array of movies and an optional error.
     */
    open func getMediaCredits<T: Media>(forPersonWithId id: String, mediaType type: T.Type, completion: @escaping ([T], NSError?) -> Void) {
        var typeString = (type is Movie.Type ? Trakt.movies : Trakt.shows)
        self.manager.request(Trakt.base + Trakt.people + "/\(id)" + typeString, parameters: Trakt.extended, headers: Trakt.Headers.Default).validate().responseJSON { response in
            guard let value = response.result.value else { completion([T](), response.result.error as NSError?); return }
            let responseObject = JSON(value)
            typeString.removeLast() // Removes 's' from the type string
            typeString.removeFirst() // Removes '/' from the type string
            var medias = [T]()
            let group = DispatchGroup()
            for (_, item) in responseObject["crew"] {
                for (_, item) in item {
                    guard let id = item[typeString]["ids"]["imdb"].string else { continue }
                    group.enter()
                    let completion: (Media?, NSError?) -> Void = { (media, _) in
                        if let media = media { medias.append(media as! T) }
                        group.leave()
                    }
                    type is Movie.Type ?  MovieManager.shared.getInfo(id, completion: completion) : ShowManager.shared.getInfo(id, completion: completion)
                }
            }
            for (_, item) in responseObject["cast"] {
                guard let id = item[typeString]["ids"]["imdb"].string else { continue }
                group.enter()
                let completion: (Media?, NSError?) -> Void = { (media, _) in
                    if let media = media { medias.append(media as! T) }
                    group.leave()
                }
                type is Movie.Type ?  MovieManager.shared.getInfo(id, completion: completion) : ShowManager.shared.getInfo(id, completion: completion)
            }
            group.notify(queue: .main, execute: { completion(medias, nil) })
        }
    }
    
    /// Downloads users latest watchlist and watchedlist from Trakt.
    open func syncUserData() {
        let queue = DispatchQueue(label: "com.popcorntime.syncData", qos: .background, attributes: .concurrent, autoreleaseFrequency: .inherit, target: .global())
        queue.async{
            WatchedlistManager<Movie>.movie.getProgress()
            WatchedlistManager<Movie>.movie.getWatched()
            WatchlistManager<Movie>.movie.getWatchlist()
            WatchedlistManager<Episode>.episode.getProgress()
            WatchedlistManager<Episode>.episode.getWatched()
            WatchlistManager<Show>.show.getWatchlist()
        }
    }
    
    /**
     Requests tmdb id for object with imdb id.
     
     - Parameter id:            Imdb id of object.
     - Parameter completion:    Completion handler containing optional tmdb id and an optional error.
     */
    open func getTMDBId(forImdbId id: String, completion: @escaping (Int?, NSError?) -> Void) {
        self.manager.request(Trakt.base + Trakt.search + Trakt.imdb + "/\(id)", headers: Trakt.Headers.Default).validate().responseJSON { (response) in
            guard let value = response.result.value else { completion(nil, response.result.error as NSError?); return }
            let responseObject = JSON(value).arrayValue.first
            
            if let type = responseObject?["type"].string  {
                completion(responseObject?[type]["ids"]["tmdb"].int, nil)
            }
            
        }
    }
    
    /**
     Requests episode info from tvdb.
     
     - Parameter id:            The tvdb identification code of the episode.
     
     - Parameter completion:    Completion handler for the request. Returns episode upon success, error upon failure.
     */
    open func getEpisodeInfo(forTvdb id: Int, completion: @escaping (Episode?, NSError?) -> Void) {
        self.manager.request(Trakt.base + Trakt.search + Trakt.tvdb + "/\(id)", parameters:Trakt.extended, headers: Trakt.Headers.Default).validate().responseJSON { (response) in
            guard let value = response.result.value else { completion(nil, response.result.error as NSError?); return }
            let responseObject = JSON(value)[0]
            
            var episode = Mapper<Episode>(context: TraktContext()).map(JSONObject: responseObject["episode"].dictionaryObject)
            episode?.show = Mapper<Show>(context: TraktContext()).map(JSONObject: responseObject["show"].dictionaryObject)
            
            TMDBManager.shared.getEpisodeScreenshots(forShowWithImdbId: episode?.show?.id, orTMDBId: episode?.show?.tmdbId, season: episode?.season ?? -1, episode: episode?.episode ?? -1) { (tmdb, image, error) in
                if let tmdb = tmdb { episode?.show?.tmdbId = tmdb }
                if let image = image { episode?.largeBackgroundImage = image }
                
                completion(episode, error)
            }
        }
    }
    
    /**
     Searches Trakt for people (crew or actor).
     
     - Parameter person:        The name of the person to search.
     
     - Parameter completion:    Completion handler for the request. Returns an array of people matching the passed in title, error upon failure.
     */
    open func search(forPerson person: String, completion: @escaping ([Person]?, NSError?) -> Void) {
        self.manager.request(Trakt.base + Trakt.search + Trakt.person, parameters: ["query": person], headers: Trakt.Headers.Default).validate().responseJSON { (response) in
            guard let value = response.result.value,
                let persons: [Person] = Mapper<Crew>().mapArray(JSONObject: value) // Type of person doesn't matter as it will succeed either way.
                else { completion(nil, response.result.error as NSError?); return }
            
            let group = DispatchGroup()
            var people = [Person]()
            
            for var person in persons {
                group.enter()
                TMDBManager.shared.getCharacterHeadshots(forPersonWithImdbId: person.imdbId, orTMDBId: person.tmdbId, completion: { (_, image, error) in
                    if let image = image { person.largeImage = image }
                    people.append(person)
                    group.leave()
                })
            }
            
            group.notify(queue: .main) { completion(people, nil) }
        }
    }
}

/// When mapping to movies or shows from Trakt, the JSON is formatted differently to the Popcorn API. This struct is used to distinguish from which API the Media is being mapped from.
struct TraktContext: MapContext {}


// MARK: Trakt OAuth

@objc public protocol TraktManagerDelegate: class {
    /// Called when a user has successfully logged in.
    @objc optional func authenticationDidSucceed()
    
    /**
     Called if a user cancels the auth process or if the requests fail.
     
     - Parameter error: The underlying error.
     */
    @objc optional func authenticationDidFail(with error: NSError)
}

extension TraktManager {
    
    /**
     First part of the Trakt authentication process.
     
     - Returns: A login view controller to be presented.
     */
    public func loginViewController() -> UIViewController {
        #if os(iOS)
            state = .random(of: 15)
            
            let vc = SFSafariViewController(url: URL(string: Trakt.base + Trakt.auth + "/authorize?client_id=" + Trakt.apiKey + "&redirect_uri=PopcornTime%3A%2F%2Ftrakt&response_type=code&state=\(state!)")!)
            vc.modalPresentationStyle = .fullScreen
            
            return vc
        #else
            return TraktAuthenticationViewController(nibName: "TraktAuthenticationViewController", bundle: TraktAuthenticationViewController.bundle)
        #endif
    }
    
    /**
     Logout of Trakt.
     
     - Returns: Boolean value indicating the sucess of the operation.
     */
    public func logout() throws {
        return try OAuthCredential.delete(withIdentifier: "trakt")
    }
    
    /**
     Checks if user is authenticated with trakt.
     
     - Returns: Boolean value indicating the signed in status of the user.
     */
    public func isSignedIn() -> Bool {
        return OAuthCredential(identifier: "trakt") != nil
    }
    
    /**
     Generate code to authenticate device on web.
     
     - Parameter completion: The completion handler for the request containing the code for the user to enter to the validation url (`https://trakt.tv/activate/authorize`), the code for the device to get the access token, the expiery date of the displat code and the time interval that the program is to check whether the user has authenticated and an optional error if request fails.
     */
    internal func generateCode(completion: @escaping (String?, String?, Date?, TimeInterval?, NSError?) -> Void) {
        self.manager.request(Trakt.base + Trakt.auth + Trakt.device + Trakt.code, method: .post, parameters: ["client_id": Trakt.apiKey]).validate().responseJSON { (response) in
            guard let value = response.result.value as? [String: AnyObject], let displayCode = value["user_code"] as? String, let deviceCode = value["device_code"] as? String, let expire = value["expires_in"] as? Int, let interval = value["interval"]  as? Int else { completion(nil, nil, nil, nil, response.result.error as NSError?); return }
            completion(displayCode, deviceCode, Date().addingTimeInterval(Double(expire)), Double(interval), nil)
        }
    }
    
    /**
     Second part of the authentication process. Calls delegate upon completion.
     
     - Parameter url: The redirect URI recieved from step 1.
     */
    public func authenticate(_ url: URL) {
        defer { state = nil }
        
        guard let query = url.query?.queryString,
            let code = query["code"],
            query["state"] == state
            else {
                delegate?.authenticationDidFail?(with: NSError(domain: "com.popcorntimetv.popcornkit.error", code: -1, userInfo: [NSLocalizedDescriptionKey: "An unknown error occured."]))
                return
        }
        
        DispatchQueue.global(qos: .default).async {
            do {
                try OAuthCredential(Trakt.base + Trakt.auth + Trakt.token,
                                    code: code,
                                    redirectURI: "PopcornTime://trakt",
                                    clientID: Trakt.apiKey,
                                    clientSecret: Trakt.apiSecret,
                                    useBasicAuthentication: false).store(withIdentifier: "trakt")
                DispatchQueue.main.sync {
                    self.delegate?.authenticationDidSucceed?()
                }
            } catch let error as NSError {
                DispatchQueue.main.sync {
                    self.delegate?.authenticationDidFail?(with: error)
                }
            }
        }
    }
}
