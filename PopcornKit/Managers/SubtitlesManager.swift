

import Alamofire
import ObjectMapper

open class SubtitlesManager: NetworkManager {
    
    /// Creates new instance of SubtitlesManager class
    open static let shared = SubtitlesManager()
    
    /**
     Load subtitles from API. Use episode or ImdbId not both. Using ImdbId rewards better results.
     
     - Parameter episode:       The show episode.
     - Parameter imdbId:        The Imdb identification code of the episode or movie.
     - Parameter limit:         The limit of subtitles to fetch as a `String`. Defaults to 500.
     
     - Parameter completion:    Completion handler called with array of subtitles and an optional error.
     */
    open func search(_ episode: Episode? = nil, imdbId: String? = nil,preferredLang: String? = nil,videoFilePath: URL? = nil, limit: String = "500", completion:@escaping ([Subtitle], NSError?) -> Void) {
        var params = [String:Any]()
        if let videoFilePath = videoFilePath {
            let videohash = OpenSubtitlesHash.hashFor(videoFilePath)
            params["moviehash"] = videohash.fileHash
            params["moviebytesize"] = videohash.fileSize
        }else if let imdbId = imdbId {
            params["imdbid"] = imdbId.replacingOccurrences(of: "tt", with: "")
        } else if let episode = episode {
            params["episode"] = String(episode.episode)
            params["query"] = episode.title
            params["season"] = String(episode.season)
        }
        params["sublanguageid"] = preferredLang ?? "all"
        
        let queue = DispatchQueue(label: "com.popcorn-time.response.queue", attributes: DispatchQueue.Attributes.concurrent)
        self.manager.request(OpenSubtitles.base+OpenSubtitles.search+params.compactMap({"\($0)-\($1)"}).joined(separator: "/"), headers: OpenSubtitles.defaultHeaders).validate().responseJSON(queue: queue) { response in
            guard
                let value = response.result.value,
                let status = response.response?.statusCode,
                response.result.isSuccess && status == 200
                else {
                    return DispatchQueue.main.async {
                        completion([], response.result.error as NSError?)
                    }
            }
            
            var subtitles = Mapper<Subtitle>().mapArray(JSONObject: value) ?? [Subtitle]()
            for subtitle in subtitles{
                while let same = subtitles.first(where: {$0.ISO639 == subtitle.ISO639 && $0.link != subtitle.link}),
                    let index = subtitles.index(of: same) {
                    if subtitle.rating > same.rating {
                        subtitles.remove(at:index)
                    }else{
                        if let ind = subtitles.index(of: subtitle){
                            subtitles.remove(at:ind)
                        }
                        break
                    }
                }
            }
        
            subtitles.sort(by: { $0.language < $1.language })
            DispatchQueue.main.async(execute: { completion(subtitles, nil) })
        }
    }
}
