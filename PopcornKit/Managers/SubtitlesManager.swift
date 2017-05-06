

import Alamofire
import AlamofireXMLRPC

open class SubtitlesManager: NetworkManager {
    
    /// Creates new instance of SubtitlesManager class
    open static let shared = SubtitlesManager()
    
    // MARK: - Private Variables.
    
    private let baseURL = "http://api.opensubtitles.org:80/xml-rpc"
    private let secureBaseURL = "https://api.opensubtitles.org:443/xml-rpc"
    private let userAgent = "Popcorn Time v1"
    private var token: String?
    
    /**
     Load subtitles from API. Use episode or ImdbId not both. Using ImdbId rewards better results.
     
     - Parameter episode:       The show episode.
     - Parameter imdbId:        The Imdb identification code of the episode or movie.
     - Parameter limit:         The limit of subtitles to fetch as a `String`. Defaults to 500.
     
     - Parameter completion:    Completion handler called with array of subtitles and an optional error.
     */
    open func search(_ episode: Episode? = nil, imdbId: String? = nil, limit: String = "500", completion:@escaping ([Subtitle], NSError?) -> Void) {
        guard let token = token else {
            login() { error in
                guard error == nil else { completion([], error); return }
                self.search(episode, imdbId: imdbId, limit: limit, completion: completion)
            }
            return
        }
        var params = ["sublanguageid": "all"]
        if let imdbId = imdbId {
            params["imdbid"] = imdbId.replacingOccurrences(of: "tt", with: "")
        } else if let episode = episode {
            params["query"] = episode.title
            params["season"] = String(episode.season)
            params["episode"] = String(episode.episode)
        }
        let limit = ["limit": limit]
        let queue = DispatchQueue(label: "com.popcorn-time.response.queue", attributes: DispatchQueue.Attributes.concurrent)
        self.manager.requestXMLRPC(secureBaseURL, methodName: "SearchSubtitles", parameters: [token, [params], limit], headers: ["User-Agent": userAgent]).validate().responseXMLRPC(queue: queue, completionHandler: { response in
            guard
                let value = response.result.value,
                let status = value[0]["status"].string?.components(separatedBy: " ").first,
                let data = value[0]["data"].array,
                response.result.isSuccess && status == "200"
                else {
                    DispatchQueue.main.async {
                        completion([], response.result.error as NSError?)
                    }
                    return
            }
            
            var subtitles = [Subtitle]()
            for info in data {
                guard
                    let subDownloadLink = info["SubDownloadLink"].string,
                    let ISO639 = info["ISO639"].string,
                    let localizedLanguageName = Locale.current.localizedString(forLanguageCode: ISO639)?.localizedCapitalized,
                    let rating = Double(info["SubRating"].string ?? "")
                    else {
                        continue
                }
                
                let subtitle = Subtitle(language: localizedLanguageName, link: subDownloadLink, ISO639: ISO639, rating: rating)
                
                if let same = subtitles.first(where: {$0.ISO639 == ISO639}),
                    let index = subtitles.index(of: same) {
                    if rating > same.rating {
                        subtitles[index] = subtitle
                    }
                } else {
                   subtitles.append(subtitle)
                }
            }
            
            subtitles.sort(by: { $0.language < $1.language })
            DispatchQueue.main.async(execute: { completion(subtitles, nil) })
        })
    }
    
    /**
     Login to OpenSubtitles API. Login is required to use the API.
     
     - Parameter completion:    Optional completion handler called when request completes. Contains an optional Error indicating the success of the operation.
     */
    public func login(_ completion: ((NSError?) -> Void)?) {
        self.manager.requestXMLRPC(secureBaseURL, methodName: "LogIn", parameters: ["", "", "en", userAgent]).validate().responseXMLRPC { response in
            guard let value = response.result.value,
                let status = value[0]["status"].string?.components(separatedBy: " ").first,
                response.result.isSuccess && status == "200" else {
                    completion?(response.result.error as NSError? ?? NSError(domain: "com.popcorntimetv.popcornkit.error", code: -1, userInfo: [NSLocalizedDescriptionKey: "An unknown error occured."]))
                    return
            }
            self.token = value[0]["token"].string
            completion?(nil)
        }
    }
    
    /**
     Logout of OpenSubtitles API. Logging out is not necessary, but good practise after an application's lifecycle has been ended. If the API was never logged-in to, the user will not be logged out.
     
     - Parameter completion: Optional completion handler called when request fails or is sucessfull. Failure indicated by optional error.
     */
    open func logout(completion: ((NSError?) -> Void)? = nil) {
        guard let token = token else { return }
        self.manager.requestXMLRPC(secureBaseURL, methodName: "LogOut", parameters: [token], headers: ["User-Agent": userAgent]).validate().responseXMLRPC { (response) in
            guard let value = response.result.value,
                let status = value[0]["status"].string?.components(separatedBy: " ").first
                , response.result.isSuccess && status == "200" else {
                    completion?(response.result.error as NSError?)
                    return
            }
            completion?(nil)
        }
    }
}
