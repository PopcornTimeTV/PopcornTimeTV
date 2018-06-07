

import Alamofire
import AlamofireXMLRPC

open class SubtitlesManager: NetworkManager {
    
    /// Creates new instance of SubtitlesManager class
    open static let shared = SubtitlesManager()
    
    /// The login token obtained by a sucessfull call of the `login` function.
    private var token: String?
    
    /**
     Load subtitles from API. Use episode or ImdbId not both. Using ImdbId rewards better results.
     
     - Parameter episode:       The show episode.
     - Parameter imdbId:        The Imdb identification code of the episode or movie.
     - Parameter limit:         The limit of subtitles to fetch as a `String`. Defaults to 500.
     
     - Parameter completion:    Completion handler called with array of subtitles and an optional error.
     */
    open func search(_ episode: Episode? = nil, imdbId: String? = nil,preferredLang: String? = nil,videoFilePath: URL? = nil, limit: String = "500", completion:@escaping ([Subtitle], NSError?) -> Void) {
        guard let token = token else {
            login() { error in
                guard error == nil else { completion([], error); return }
                self.search(episode, imdbId: imdbId, limit: limit, completion: completion)
            }
            return
        }
        var params:[String:Any] = ["sublanguageid": preferredLang ?? "all"]
        if let videoFilePath = videoFilePath {
            let videohash = OpenSubtitlesHash.hashFor(videoFilePath)
            params["moviehash"] = videohash.fileHash
            params["moviebytesize"] = videohash.fileSize
        }else if let imdbId = imdbId {
            params["imdbid"] = imdbId.replacingOccurrences(of: "tt", with: "")
        } else if let episode = episode {
            params["query"] = episode.title
            params["season"] = String(episode.season)
            params["episode"] = String(episode.episode)
        }
        let limit = ["limit": limit]
        let queue = DispatchQueue(label: "com.popcorn-time.response.queue", attributes: DispatchQueue.Attributes.concurrent)
        self.manager.requestXMLRPC(OpenSubtitles.base, methodName: OpenSubtitles.search, parameters: [token, [params], limit], headers: OpenSubtitles.defaultHeaders).validate().responseXMLRPC(queue: queue) { response in
            guard
                let value = response.result.value,
                let status = value[0]["status"].string?.components(separatedBy: " ").first,
                let data = value[0]["data"].array,
                response.result.isSuccess && status == "200"
                else {
                    return DispatchQueue.main.async {
                        completion([], response.result.error as NSError?)
                    }
            }
            
            var subtitles = [Subtitle]()
            for info in data {
                guard
                    let subDownloadLink = info["SubDownloadLink"].string?.replacingOccurrences(of: ".gz", with: ""),
                    let ISO639 = info["ISO639"].string,
                    let localizedLanguageName = ((Locale.current.localizedString(forLanguageCode: ISO639)?.localizedCapitalized) ?? (Locale.current.localizedString(forLanguageCode: ISO639.replacingOccurrences(of: "pob", with: "pt_BR"))) ?? (Locale.current.localizedString(forLanguageCode: ISO639.replacingOccurrences(of: "pb", with: "pt_BR")))),
                    let rating = Double(info["SubRating"].string ?? "")
                    else {
                        continue
                }
                var tmpLanguage = localizedLanguageName
                
                //append BR at the end
                if ISO639 == "pb" || ISO639 == "pob" {
                    tmpLanguage = NSString(format: "%@ BR", localizedLanguageName) as String
                }
                
                // also use capitalized string for sorting correctly
                let subtitle = Subtitle(language: tmpLanguage.capitalized, link: subDownloadLink, ISO639: ISO639, rating: rating)
                
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
        }
    }
    
    /**
     Login to OpenSubtitles API. Login is required to use the API.
     
     - Parameter completion:    Optional completion handler called when request completes. Contains an optional Error indicating the success of the operation.
     */
    public func login(_ completion: ((NSError?) -> Void)?) {
        self.manager.requestXMLRPC(OpenSubtitles.base, methodName: OpenSubtitles.logIn, parameters: ["", "", "en", OpenSubtitles.userAgent]).validate().responseXMLRPC { response in
            guard
                let value = response.result.value,
                let status = value[0]["status"].string?.components(separatedBy: " ").first,
                response.result.isSuccess && status == "200"
                else {
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
        self.manager.requestXMLRPC(OpenSubtitles.base, methodName: OpenSubtitles.logOut, parameters: [token], headers: OpenSubtitles.defaultHeaders).validate().responseXMLRPC { (response) in
            guard
                let value = response.result.value,
                let status = value[0]["status"].string?.components(separatedBy: " ").first,
                response.result.isSuccess && status == "200"
                else {
                    completion?(response.result.error as NSError?)
                    return
            }
            completion?(nil)
        }
    }
}
