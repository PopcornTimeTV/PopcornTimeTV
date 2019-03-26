

import Foundation
import Alamofire
import SwiftyJSON

open class TMDBManager: NetworkManager {
    
    /// Creates new instance of TMDBManager class
    public static let shared = TMDBManager()
    
    /**
     Load movie posters from TMDB. Either a tmdb id or an imdb id must be passed in.
     
     - Parameter forMediaOfType:    The type of the media, either movie or show.
     - Parameter withImdbId:        The imdb id of the media. If media hasn't get recieved it's tmdb id it will be requested using this imdb id.
     - Parameter orTMDBId:          The tmdb id of the media.
     
     - Parameter completion:        The completion handler for the request containing an optional tmdb id, largeImageUrl and an optional error.
     */
    open func getPoster(forMediaOfType type: TMDB.MediaType, withImdbId imdb: String? = nil, orTMDBId tmdb: Int? = nil, completion: @escaping (Int?, String?, NSError?) -> Void) {
        
        guard let id = tmdb else {
            guard let id = imdb else { completion(nil, nil, nil); return }
            TraktManager.shared.getTMDBId(forImdbId: id, completion: { (tmdb, error) in
                guard let tmdb = tmdb else { completion(nil, nil, error); return }
                self.getPoster(forMediaOfType: type, orTMDBId: tmdb, completion: completion)
            })
            return
        }
        
        self.manager.request(TMDB.base + "/" + type.rawValue + "/\(id)" + TMDB.images, parameters: TMDB.defaultHeaders).validate().responseJSON { (response) in
            guard let value = response.result.value else { completion(id, nil, response.result.error as NSError?); return }
            let responseDict = JSON(value)
            
            var image: String?
            if let poster = responseDict["posters"].first?.1["file_path"].string {
                image = "https://image.tmdb.org/t/p/w780" + poster
            }
            completion(id, image, nil)
            image = nil
        }
    }
    
    /**
     Load season posters from TMDB. Either a tmdb id or an imdb id must be passed in.
     
     - Parameter ofShowWithImdbId:  The imdb id of the show. If show hasn't get recieved it's tmdb id it will be requested using this imdb id.
     - Parameter orTMDBId:          The tmdb id of the show.
     - Parameter season:            The season of the show.
     
     - Parameter completion:    The completion handler for the request containing an optional tmdb id, image and an optional error.
     */
    open func getSeasonPoster(ofShowWithImdbId imdb: String? = nil, orTMDBId tmdb: Int? = nil, season: Int, completion: @escaping (Int?, String?, NSError?) -> Void) {
        
        guard let id = tmdb else {
            guard let id = imdb else { completion(nil, nil, nil); return }
            TraktManager.shared.getTMDBId(forImdbId: id, completion: { (tmdb, error) in
                guard let tmdb = tmdb else { completion(nil, nil, error); return }
                self.getSeasonPoster(orTMDBId: tmdb, season: season, completion: completion)
            })
            return
        }
        
        self.manager.request(TMDB.base + TMDB.tv + "/\(id)" + TMDB.season + "/\(season)" + TMDB.images, parameters: TMDB.defaultHeaders).validate().responseJSON { (response) in
            guard let value = response.result.value else { completion(id, nil, response.result.error as NSError?); return }
            let responseDict = JSON(value)
            
            var image: String?
            if let poster = responseDict["posters"].first?.1["file_path"].string {
                image = "https://image.tmdb.org/t/p/w500" + poster
            }
            completion(id, image, nil)
        }
    }
    
    /**
     Load episode screenshots from TMDB. Either a tmdb id or an imdb id must be passed in.
     
     - Parameter forShowWithImdbId: The imdb id of the show that the episode is in. If show hasn't get recieved it's tmdb id it will be requested using this imdb id.
     - Parameter orTMDBId:          The tmdb id of the show.
     - Parameter season:            The season number of the episode.
     - Parameter episode:           The episode number of the episode.
     
     - Parameter completion:        The completion handler for the request containing an optional tmdb id, largeImageUrl and an optional error.
     */
    open func getEpisodeScreenshots(forShowWithImdbId imdb: String? = nil, orTMDBId tmdb: Int? = nil, season: Int, episode: Int, completion: @escaping (Int?, String?, NSError?) -> Void) {
        
        guard let id = tmdb else {
            guard let id = imdb else { completion(nil, nil, nil); return }
            TraktManager.shared.getTMDBId(forImdbId: id, completion: { (tmdb, error) in
                guard let tmdb = tmdb else { completion(nil, nil, error); return }
                self.getEpisodeScreenshots(orTMDBId: tmdb, season: season, episode: episode, completion: completion)
            })
            return
        }
        
        self.manager.request(TMDB.base + TMDB.tv + "/\(id)" + TMDB.season + "/\(season)" + TMDB.episode + "/\(episode)" + TMDB.images, parameters: TMDB.defaultHeaders).validate().responseJSON { (response) in
            guard let value = response.result.value else { completion(id, nil, response.result.error as NSError?); return }
            let responseDict = JSON(value)
            
            var image: String?
            if let screenshot = responseDict["stills"].first?.1["file_path"].string {
                image = "https://image.tmdb.org/t/p/w1280" + screenshot
            }
            completion(id, image, nil)
        }
    }
    
    /**
     Load character headshots from TMDB. Either a tmdb id or an imdb id must be passed in.
     
     - Parameter forPersonWithImdbId:   The imdb id of the person. If character hasn't get recieved it's tmdb id it will be requested using this imdb id.
     - Parameter orTMDBId:              The tmdb id of the person.
     
     - Parameter completion:            The completion handler for the request containing an optional tmdb id, largeImageUrl and an optional error.
     */
    open func getCharacterHeadshots(forPersonWithImdbId imdb: String? = nil, orTMDBId tmdb: Int? = nil, completion: @escaping (Int?, String?, NSError?) -> Void) {
        
        guard let id = tmdb else {
            guard let id = imdb else { completion(nil, nil, nil); return }
            TraktManager.shared.getTMDBId(forImdbId: id, completion: { (tmdb, error) in
                guard let tmdb = tmdb else { completion(nil, nil, error); return }
                self.getCharacterHeadshots(orTMDBId: tmdb, completion: completion)
            })
            return
        }
        
        self.manager.request(TMDB.base + TMDB.person + "/\(id)" + TMDB.images, parameters: TMDB.defaultHeaders).validate().responseJSON { (response) in
            guard let value = response.result.value else { completion(id, nil, response.result.error as NSError?); return }
            let responseDict = JSON(value)
            
            var image: String?
            if let headshot = responseDict["profiles"].first?.1["file_path"].string {
                image = "https://image.tmdb.org/t/p/w780" + headshot
            }
            completion(id, image, nil)
        }
    }
    
    /**
     Load Movie or TV Show logos from Fanart.tv.
     
     - Parameter forMediaOfType:    The type of the media. Only available for movies and shows.
     - Parameter id:                The imdb id of the movie or the tvdb id of the show.
     
     - Parameter completion:        The completion handler for the request containing an optional image and an optional error.
     */
    open func getLogo(forMediaOfType type: Trakt.MediaType, id: String, completion: @escaping (String?, NSError?) -> Void) {
        self.manager.request(Fanart.base + (type == .movies ? Fanart.movies : Fanart.tv) + "/\(id)", parameters: Fanart.defaultParameters).validate().responseJSON { (response) in
            guard let value = response.result.value else { completion(nil, response.result.error as NSError?); return }
            let responseDict = JSON(value)
            
            let typeString = type == .movies ? "movie" : "tv"
            let image = responseDict["hd\(typeString)logo"].first(where: { $0.1["lang"].string == "en" })?.1["url"].string

            completion(image, nil)
        }
        
    }
}
