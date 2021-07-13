

import ObjectMapper

open class ShowManager: NetworkManager {
    
    /// Creates new instance of ShowManager class
    public static let shared = ShowManager()

    /// Create a cache for loaded shows
    let cache = ShowCache()

    /// Possible filters used in API call.
    public enum Filters: String {
        case popularity = "popularity"
        case year = "year"
        case date = "updated"
        case rating = "rating"
        case trending = "seeds"
        
        public static let array = [trending, popularity, rating, date, year]
        
        public var string: String {
            switch self {
            case .popularity:
                return "Popular".localized
            case .year:
                return "New".localized
            case .date:
                return "Recently Added".localized
            case .rating:
                return "Top Rated".localized
            case .trending:
                return "Trending".localized
            }
        }
    }
    
    /**
     Load TV Shows from API.
     
     - Parameter page:       The page number to load.
     - Parameter filterBy:   Sort the response by Popularity, Year, Date Rating, Alphabet or Trending.
     - Parameter genre:      Only return shows that match the provided genre.
     - Parameter searchTerm: Only return shows that match the provided string.
     - Parameter orderBy:    Ascending or descending.
     
     - Parameter completion: Completion handler for the request. Returns array of shows upon success, error upon failure.
     */
    open func load(
        _ page: Int,
        filterBy filter: Filters,
        genre: Genres,
        searchTerm: String?,
        orderBy order: Orders,
        completion: @escaping ([Show]?, NSError?) -> Void) {
        var params: [String: Any] = [
            "page": page,
            "sort": filter.rawValue,
            "genre": genre.rawValue.replacingOccurrences(of: " ", with: "-").lowercased(),
            "order": order.rawValue,
            "ver": "6.1.2",
            "os": "mac"
        ]
        if let searchTerm = searchTerm , !searchTerm.isEmpty {
            params["keywords"] = searchTerm
        }
        
//        http://api.pctapi.com/shows?cb=0.47824454936239214&sort=seeds&page=1&ver=6.1.2&os=mac
        self.manager.request(PopcornShows.base + PopcornShows.shows, method: .get, parameters: params).validate().responseJSON { response in
            guard let value = response.result.value as? NSDictionary, let shows = Mapper<Show>().mapArray(JSONObject: value["MovieList"]) else {completion(nil, response.result.error as NSError?); return}

            for show in shows {
                self.cache.addShow(show)
            }
            completion(shows, nil)
        }
        
//        self.manager.request(PopcornShows.base + PopcornShows.shows + "/\(page)", method: .get, parameters: params).validate().responseJSON { response in
//            guard let value = response.result.value else {completion(nil, response.result.error as NSError?); return}
//            completion(Mapper<Show>().mapArray(JSONObject: value), nil)
//        }
    }
    
    /**
     Get more show information.
     
     - Parameter imdbId:        The imdb identification code of the show.
     
     - Parameter completion:    Completion handler for the request. Returns show upon success, error upon failure.
     */
    open func getInfo(_ imdbId: String, completion: @escaping (Show?, NSError?) -> Void) {
        let params: [String: Any] = [
            "imdb": imdbId,
            "quality": "720p,1080p,2160p,2160,4k,4K,3d,3D,h265",
            "os": "mac",
            "ver": "6.1.2"
        ]
        self.manager.request(PopcornShows.base + PopcornShows.show, method: .get, parameters: params).validate().responseJSON { response in
            guard let value = response.result.value as? NSDictionary, var cachedShow = self.cache.show(imdbId) else {completion(nil, response.result.error as NSError?); return}
            DispatchQueue.global(qos:.background).async{

                for (season, eps) in value {
                    let episodes = eps as! NSArray
                    for ep in episodes {
                        if var episode = Mapper<Episode>().map(JSONObject: ep) {
                            if episode.torrents.count > 0 {
                                episode.show = cachedShow
                                cachedShow.episodes.append(episode)
                            }
                        }
                    }
                }

                DispatchQueue.main.sync{
                    completion(cachedShow, nil)
                }
            }
        }
    }
}
