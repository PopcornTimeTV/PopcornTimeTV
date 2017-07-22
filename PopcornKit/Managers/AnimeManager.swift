

import ObjectMapper

@available(*, unavailable, message: "Anime API does not provide sufficient metadata to be included in the application. If the API is not improved, this class shall be removed in future releases.")
open class AnimeManager: NetworkManager {
    /*
    
    /// Creates new instance of AnimeManager class
    open static let shared = AnimeManager()
    
    /// Possible genres used in API call.
    public enum Genres: String {
        case all = "All"
        case action = "Action"
        case adventure = "Adventure"
        case comedy = "Comedy"
        case dementia = "Dementia"
        case demons = "Demons"
        case drama = "Drama"
        case ecchi = "Ecchi"
        case fantasy = "Fantasy"
        case game = "Game"
        case genderBender = "Gender Bender"
        case gore = "Gore"
        case harem = "Harem"
        case historical = "Historical"
        case horror = "Horror"
        case kids = "Kids"
        case magic = "Magic"
        case mahouShoujo = "Mahou Shoujo"
        case mahouShounen = "Mahou Shounen"
        case martialArts = "Martial Arts"
        case mecha = "Mecha"
        case military = "Military"
        case music = "Music"
        case mystery = "Mystery"
        case parody = "Parody"
        case police = "Police"
        case psychological = "Psychological"
        case racing = "Racing"
        case romance = "Romance"
        case samurai = "Samurai"
        case school = "School"
        case sciFi = "Sci-Fi"
        case shounenAi = "Shounen Ai"
        case shoujoAi = "Shoujo Ai"
        case sliceOfLife = "Slice of Life"
        case space = "Space"
        case sports = "Sports"
        case supernatural = "Supernatural"
        case superPower = "Super Power"
        case thriller = "Thriller"
        case vampire = "Vampire"
        case yuri = "Yuri"
        
        public static let array = [all, action, adventure, comedy, dementia, demons, drama, ecchi, fantasy, game, genderBender, gore, harem, historical, horror, kids, magic, mahouShoujo, mahouShounen, martialArts, mecha, military, music, mystery, parody, police, psychological, racing, romance, samurai, school, sciFi, shounenAi, shoujoAi, sliceOfLife, space, sports, supernatural, superPower, thriller, vampire, yuri]
    }
    
    /// Possible filters used in API call.
    public enum Filters: String {
        case popularity = "popularity"
        case year = "year"
        case date = "updated"
        case rating = "rating"
        
        public static let array = [popularity, rating, date, year]
        
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
            }
        }
    }
    
    /**
     Load Anime from API.
     
     - Parameter page:       The page number to load.
     - Parameter filterBy:   Sort the response by Popularity, Year, Date Rating, Alphabet or Trending.
     - Parameter genre:      Only return anime that match the provided genre.
     - Parameter searchTerm: Only return animes that match the provided string.
     - Parameter orderBy:    Ascending or descending.
     
     - Parameter completion: Completion handler for the request. Returns array of animes upon success, error upon failure.
     */
    open func load(
        _ page: Int,
        filterBy filter: Filters,
        genre: Genres,
        searchTerm: String?,
        orderBy order: Orders,
        completion: @escaping (_ shows: [Show]?, _ error: NSError?) -> Void) {
        var params: [String: Any] = ["sort": filter.rawValue, "type": genre.rawValue, "order": order.rawValue]
        if let searchTerm = searchTerm, !searchTerm.isEmpty {
            params["keywords"] = searchTerm
        }
        self.manager.request(Popcorn.base + Popcorn.animes + "/\(page)", parameters: params).validate().responseJSON { response in
            guard let value = response.result.value else {completion(nil, response.result.error as NSError?); return}
            completion(Mapper<Show>().mapArray(JSONObject: value), nil)
        }
    }
    
    /**
     Get more anime information.
     
     - Parameter id:            The identification code of the anime.
     
     - Parameter completion:    Completion handler for the request. Returns show upon success, error upon failure.
     */
    open func getInfo(_ id: String, completion: @escaping (_ show: Show?, _ error: NSError?) -> Void) {
        self.manager.request(Popcorn.base + Popcorn.anime + "/\(id)").validate().responseJSON { response in
            guard let value = response.result.value else {completion(nil, response.result.error as NSError?); return}
            completion(Mapper<Show>().map(JSONObject: value), nil)
        }
    }
 */
}
