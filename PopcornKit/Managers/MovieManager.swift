

import ObjectMapper
import SwiftyJSON

open class MovieManager: NetworkManager {
    
    /// Creates new instance of MovieManager class
    open static let shared = MovieManager()
    
    /// Possible genres used in API call.
    public enum Genres: String {
        case all = "All"
        case action = "Action"
        case adventure = "Adventure"
        case animation = "Animation"
        case comedy = "Comedy"
        case crime = "Crime"
        case disaster = "Disaster"
        case documentary = "Documentary"
        case drama = "Drama"
        case family = "Family"
        case fanFilm = "Fan Film"
        case fantasy = "Fantasy"
        case filmNoir = "Film Noir"
        case history = "History"
        case holiday = "Holiday"
        case horror = "Horror"
        case indie = "Indie"
        case music = "Music"
        case mystery = "Mystery"
        case road = "Road"
        case romance = "Romance"
        case sciFi = "Science Fiction"
        case short = "Short"
        case sport = "Sports"
        case sportingEvent = "Sporting Event"
        case suspense = "Suspense"
        case thriller = "Thriller"
        case war = "War"
        case western = "Western"
        
        public static let array = [all, action, adventure, animation, comedy, crime, disaster, documentary, drama, family, fanFilm, fantasy, filmNoir, history, holiday, horror, indie, music, mystery, road, romance, sciFi, short, sport, sportingEvent, suspense, thriller, war, western]
    }
    
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
                return "Popular"
            case .year:
                return "New"
            case .date:
                return "Recently Added"
            case .rating:
                return "Top Rated"
            case .trending:
                return "Trending"
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
     
     - Parameter completion: Completion handler for the request. Returns array of movies upon success, error upon failure.
     */
    open func load(
        _ page: Int,
        filterBy filter: Filters,
        genre: Genres,
        searchTerm: String?,
        orderBy order: Orders,
        completion: @escaping (_ movies: [Movie]?, _ error: NSError?) -> Void) {
        var params: [String: Any] = ["sort": filter.rawValue, "order": order.rawValue, "genre": genre.rawValue.replacingOccurrences(of: " ", with: "-").lowercased()]
        if let searchTerm = searchTerm , !searchTerm.isEmpty {
            params["keywords"] = searchTerm
        }
        self.manager.request(Popcorn.base + Popcorn.movies + "/\(page)", parameters: params).validate().responseJSON { response in
            guard let value = response.result.value else {
                completion(nil, response.result.error as NSError?)
                return
            }
            completion(Mapper<Movie>().mapArray(JSONObject: value), nil)
        }
    }
    
    /**
     Get more movie information.
     
     - Parameter imdbId:        The imdb identification code of the movie.
     
     - Parameter completion:    Completion handler for the request. Returns movie upon success, error upon failure.
     */
    open func getInfo(_ imdbId: String, completion: @escaping (_ movie: Movie?, _ error: NSError?) -> Void) {
        self.manager.request(Popcorn.base + Popcorn.movie + "/\(imdbId)").validate().responseJSON { response in
            guard let value = response.result.value else {completion(nil, response.result.error as NSError?); return}
            completion(Mapper<Movie>().map(JSONObject: value), nil)
        }
    }
    
}
