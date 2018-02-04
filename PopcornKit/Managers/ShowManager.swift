

import ObjectMapper

open class ShowManager: NetworkManager {
    
    /// Creates new instance of ShowManager class
    open static let shared = ShowManager()
    
    /// Possible filters used in API call.
    public enum Filters: String {
        case popularity = "popularity"
        case year = "year"
        case date = "updated"
        case rating = "rating"
        case trending = "trending"
        
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
        var params: [String: Any] = ["sort": filter.rawValue, "genre": genre.rawValue.replacingOccurrences(of: " ", with: "-").lowercased(), "order": order.rawValue]
        if let searchTerm = searchTerm , !searchTerm.isEmpty {
            params["keywords"] = searchTerm
        }
        self.manager.request(Popcorn.base + Popcorn.shows + "/\(page)", method: .get, parameters: params).validate().responseJSON { response in
            guard let value = response.result.value else {completion(nil, response.result.error as NSError?); return}
            completion(Mapper<Show>().mapArray(JSONObject: value), nil)
        }
    }
    
    /**
     Get more show information.
     
     - Parameter imdbId:        The imdb identification code of the show.
     
     - Parameter completion:    Completion handler for the request. Returns show upon success, error upon failure.
     */
    open func getInfo(_ imdbId: String, completion: @escaping (Show?, NSError?) -> Void) {
        self.manager.request(Popcorn.base + Popcorn.show + "/\(imdbId)", method: .get).validate().responseJSON { response in
            guard let value = response.result.value else {completion(nil, response.result.error as NSError?); return}
            completion(Mapper<Show>().map(JSONObject: value), nil)
        }
    }
}
