

import Alamofire
import ObjectMapper

open class SubtitlesManager: NetworkManager {
    
    /// Creates new instance of SubtitlesManager class
    public static let shared = SubtitlesManager()
    
    /**
     Load subtitles from API. Use episode or ImdbId not both. Using ImdbId rewards better results.
     
     - Parameter episode:       The show episode.
     - Parameter imdbId:        The Imdb identification code of the episode or movie.
     - Parameter limit:         The limit of subtitles to fetch as a `String`. Defaults to 500.
     - Parameter videoFilePath: The path of the video for subtitle retrieval `URL`. Defaults to nil.
     
     - Parameter completion:    Completion handler called with array of subtitles and an optional error.
     */
    open func search(_ episode: Episode? = nil, imdbId: String? = nil,preferredLang: String? = nil,videoFilePath: URL? = nil, limit: String = "500", completion:@escaping (Dictionary<String, [Subtitle]>, NSError?) -> Void) {
        let params = getParams(episode, imdbId: imdbId, preferredLang: preferredLang, videoFilePath: videoFilePath, limit: limit)
        
        let queue = DispatchQueue(label: "com.popcorn-time.response.queue", attributes: DispatchQueue.Attributes.concurrent)
        self.manager.request(OpenSubtitles.base+OpenSubtitles.search+params.compactMap({"\($0)-\($1)"}).joined(separator: "/"), headers: OpenSubtitles.defaultHeaders).validate().responseJSON(queue: queue) { response in
            guard
                let value = response.result.value,
                let status = response.response?.statusCode,
                response.result.isSuccess && status == 200
                else {
                    return DispatchQueue.main.async {
                        completion([:], response.result.error as NSError?)
                    }
            }
            
            let subtitles = Mapper<Subtitle>().mapArray(JSONObject: value) ?? [Subtitle]()
            var allSubtitles = Dictionary<String, [Subtitle]>()
            for subtitle in subtitles {
                let language = subtitle.language
                var languageSubtitles = allSubtitles[language]
                if languageSubtitles == nil {
                    languageSubtitles = [Subtitle]()
                }
                languageSubtitles?.append(subtitle)
                allSubtitles[language] = languageSubtitles
            }
            
            DispatchQueue.main.async(execute: { completion(self.removeDuplicates(sourceSubtitles: allSubtitles), nil) })
        }
    }
    
    /**
     Remove duplicates from subtitles
     
     - Parameter sourceSubtitles:   The subtitles that may contain duplicate subtitles arranged per language in a Dictionary
     - Returns: A new dictionary with the duplicate subtitles removed
     */
    
    private func removeDuplicates(sourceSubtitles: Dictionary<String, [Subtitle]>) -> Dictionary<String, [Subtitle]> {
        var subtitlesWithoutDuplicates = Dictionary<String, [Subtitle]>()
        
        for (languageName, languageSubtitles) in sourceSubtitles {
            var seenSubtitles = Set<String>()
            var uniqueSubtitles = [Subtitle]()
            for subtitle in languageSubtitles {
                if !seenSubtitles.contains(subtitle.name) {
                    uniqueSubtitles.append(subtitle)
                    seenSubtitles.insert(subtitle.name)
                }
            }
            subtitlesWithoutDuplicates[languageName] = uniqueSubtitles
        }
        
        return subtitlesWithoutDuplicates
    }
    
    private func getParams(_ episode: Episode? = nil, imdbId: String? = nil,preferredLang: String? = nil,videoFilePath: URL? = nil, limit: String = "500") -> [String:Any] {
        var params = [String:Any]()
        if let episode = episode {
            if let id = episode.show?.id {
                params["imdbid"] = String(id)
            } else {
                params["query"] = episode.title
            }
            params["episode"] = String(episode.episode)
            params["season"] = String(episode.season)
        } else if let imdbId = imdbId {
            params["imdbid"] = imdbId.replacingOccurrences(of: "tt", with: "")
        } else if let videoFilePath = videoFilePath {
            let videohash = OpenSubtitlesHash.hashFor(videoFilePath)
            params["moviehash"] = videohash.fileHash
            params["moviebytesize"] = videohash.fileSize
        }
//        if let videoFilePath = videoFilePath {
//            let videohash = OpenSubtitlesHash.hashFor(videoFilePath)
//            params["moviehash"] = videohash.fileHash
//            params["moviebytesize"] = videohash.fileSize
//        }else if let imdbId = imdbId {
//            params["imdbid"] = imdbId.replacingOccurrences(of: "tt", with: "")
//        } else if let episode = episode {
//            params["episode"] = String(episode.episode)
//            params["query"] = episode.title
//            params["season"] = String(episode.season)
//        }
//        params["sublanguageid"] = preferredLang ?? "all"
        return params
    }
}
