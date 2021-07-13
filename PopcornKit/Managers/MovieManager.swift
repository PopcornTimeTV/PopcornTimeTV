

import ObjectMapper

open class MovieManager: NetworkManager {
    
    /// Creates new instance of MovieManager class
    public static let shared = MovieManager()
    
    /// Possible filters used in API call.
    public enum Filters: String {
        case trending = "trending"
        case popularity = "seeds"
        case rating = "rating"
        case date = "last added"
        case year = "year"
        
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
     Load Movies from API.
     
     - Parameter page:       The page number to load.
     - Parameter filterBy:   Sort the response by Popularity, Year, Date Rating, Alphabet or Trending.
     - Parameter genre:      Only return movies that match the provided genre.
     - Parameter searchTerm: Only return movies that match the provided string.
     - Parameter orderBy:    Ascending or descending.
     - Parameter ver:        Try to keep this in line with PopcornTime Desktop
     - Parameter os:         For now, hardcoded to "mac"
     
     - Parameter completion: Completion handler for the request. Returns array of movies upon success, error upon failure.
     */
    open func load(
        _ page: Int,
        filterBy filter: Filters,
        genre: Genres,
        searchTerm: String?,
        orderBy order: Orders,
        completion: @escaping ([Movie]?, NSError?) -> Void) {
        var params: [String: Any] = [
            "page": page,
            "sort": filter.rawValue,
            "order": order.rawValue,
            "genre": genre.rawValue.replacingOccurrences(of: " ", with: "-").lowercased(),
            "ver": "6.1.2",
            "os": "mac"
        ]
        if let searchTerm = searchTerm , !searchTerm.isEmpty {
            params["keywords"] = searchTerm
        }
        self.manager.request(PopcornMovies.base + PopcornMovies.movies, parameters: params).validate().responseJSON { response in
            guard let value = response.result.value as? NSDictionary else {
                completion(nil, response.result.error as NSError?)
                return
            }
            completion(Mapper<Movie>().mapArray(JSONObject: value["MovieList"]), nil)
        }
    }
    
    /**
     Get more movie information.
     
     - Parameter imdbId:        The imdb identification code of the movie.
     
     - Parameter completion:    Completion handler for the request. Returns movie upon success, error upon failure.
     */
    open func getInfo(_ imdbId: String, completion: @escaping (Movie?, NSError?) -> Void) {
        let params: [String: Any] = [
            "imdb": imdbId,
            "quality": "720p,1080p,2160p,2160,4k,4K,3d,3D,h265",
            "os": "mac",
            "ver": "6.1.2"
        ]
        self.manager.request(PopcornMovies.base + PopcornMovies.movie, parameters: params).validate().responseJSON { response in
            guard let value = response.result.value as? NSDictionary else {completion(nil, response.result.error as NSError?); return}
            DispatchQueue.global(qos: .background).async {
                let mappedItem = Mapper<Movie>().map(JSONObject: value)
                DispatchQueue.main.sync{completion(mappedItem, nil)}
            }
        }
    }
    
}
