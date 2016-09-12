


import Foundation
import Alamofire
import AlamofireXMLRPC

@objc class Subtitle: NSObject {
    
    var language: String!
    var encoding: String!
    var fileAddress: String!
    var filePath: String!
    var fileName: String!
    var index: NSNumber? // Obj-C Bridging support
    
    override init() {
        super.init()
    }
    
    convenience init(language: String, fileAddress: String!, fileName: String!, encoding: String!) {
        self.init()
        
        self.language = language
        self.fileAddress = fileAddress
        self.fileName = fileName
        self.encoding = encoding
    }
    
    override var description: String {
        get {
            return "<\(self.dynamicType)> language: \"\(self.language)\"\n file: \"\(self.fileAddress)\"\n"
        }
    }
    
    func downloadSubtitle(completion: ((filePath: String?) -> Void)?) {
        Alamofire.request(.GET, self.fileAddress)
            .responseData { response in
                if let data = response.data {
                    let paths = NSSearchPathForDirectoriesInDomains(.CachesDirectory, .UserDomainMask, true)
                    if let cachcesDirectory = paths.first {
                        do {
                            var path = cachcesDirectory.stringByAppendingPathComponent("Subtitles").stringByAppendingPathComponent(self.language)
                            var isDir:ObjCBool = false
                            if !NSFileManager.defaultManager().fileExistsAtPath(path, isDirectory: &isDir)
                            {
                                try NSFileManager.defaultManager().createDirectoryAtPath(path, withIntermediateDirectories: false, attributes: nil)
                            }
                            path = path.stringByAppendingPathComponent(self.fileAddress.lastPathComponent)
                            try data.writeToFile(path, options: .DataWritingAtomic)
                            let zip = ZKFileArchive(archivePath: path)
                            if zip.inflateToDiskUsingResourceFork(false) == 1 {
                                try NSFileManager.defaultManager().removeItemAtPath(path)
                            }
                            self.filePath = path.stringByDeletingLastPathComponent.stringByAppendingPathComponent(self.fileName)
                            completion?(filePath: self.filePath)
                        } catch NSCocoaError.FileWriteFileExistsError {
                            self.filePath = cachcesDirectory.stringByAppendingPathComponent("Subtitles").stringByAppendingPathComponent(self.language).stringByAppendingPathComponent(self.fileName)
                            if NSFileManager.defaultManager().fileExistsAtPath(self.filePath) {
                                do {
                                    let dirContents = try NSFileManager.defaultManager().contentsOfDirectoryAtPath(self.filePath.stringByDeletingLastPathComponent)
                                    let srts = dirContents.filter({ $0.containsString(".srt") })
                                    if let first = srts.first {
                                        self.filePath = cachcesDirectory.stringByAppendingPathComponent("Subtitles").stringByAppendingPathComponent(self.language).stringByAppendingPathComponent(first)
                                    }
                                } catch let error as NSError {
                                    print(error)
                                }
                            }
                            completion?(filePath: self.filePath)
                        } catch {
                            completion?(filePath: self.filePath)
                        }
                    } else {
                        completion?(filePath: self.filePath)
                    }
                } else {
                    completion?(filePath: self.filePath)
                }
        }
    }
    
}

@objc class SubtitleManager: NSObject, ZipKitDelegate {
    
    typealias CompletionBlock = ((name: String?, path: String?) -> Void)?
    
    var completion: CompletionBlock
    
    private let baseURL = "http://api.opensubtitles.org:80/xml-rpc"
    private let secureBaseURL = "https://api.opensubtitles.org:443/xml-rpc"
    private let userAgent = "Popcorn Time v1"
    private var token: String!
    
    class func sharedManager() -> SubtitleManager {
        struct Struct {
            static let Instance = SubtitleManager()
        }
        
        return Struct.Instance
    }
    
    override init() {
        super.init()
        
        let paths = NSSearchPathForDirectoriesInDomains(.CachesDirectory, .UserDomainMask, true)
        if let cachcesDirectory = paths.first {
            let path = cachcesDirectory.stringByAppendingPathComponent("Subtitles")
            do {
                try NSFileManager.defaultManager().createDirectoryAtPath(path, withIntermediateDirectories: false, attributes: nil)
            } catch {
                
            }
        }
    }
    
    func login(completion: (success: Bool) -> Void) {
        AlamofireXMLRPC.request(secureBaseURL, methodName: "LogIn", parameters: ["", "", "en", userAgent]).validate().responseXMLRPC { response in
            guard response.result.isSuccess && Int(response.result.value![0]["status"].string!.componentsSeparatedByString(" ").first!)! == 200 else {
                print("Error is \(response.result.error!)")
                completion(success: false)
                return
            }
            self.token = response.result.value![0]["token"].string
            completion(success: true)
        }
    }
    
    func search(episodeName: String?, episodeSeason: Int?, episodeNumber: Int?, imdbId: String?, completion: (subtitles: [Subtitle]?) -> Void) {
        self.login { success in
            if success {
                var params: XMLRPCStructure = ["sublanguageid": "all"]
                if let imdbId = imdbId {
                    params["imdbid"] = imdbId.stringByReplacingOccurrencesOfString("tt", withString: "")
                } else {
                    params["query"] = episodeName
                    params["season"] = String(episodeSeason!)
                    params["episode"] = String(episodeNumber!)
                }
                let array: XMLRPCArray = [params]
                let limit: XMLRPCStructure = ["limit": "300"]
                let queue = dispatch_queue_create("com.popcorn-time.response.queue", DISPATCH_QUEUE_CONCURRENT)
                AlamofireXMLRPC.request(self.secureBaseURL, methodName: "SearchSubtitles", parameters: [self.token, array, limit], headers: ["User-Agent": self.userAgent]).validate().response(queue: queue, responseSerializer: Request.XMLRPCResponseSerializer(), completionHandler: { response in
                    guard response.result.isSuccess && Int(response.result.value![0]["status"].string!.componentsSeparatedByString(" ").first!)! == 200 else {
                        print("Error is \(response.result.error!)")
                        return
                    }
                    if let response = response.result.value![0]["data"].array {
                        var subtitles = [Subtitle]()
                        for info in response {
                            if !subtitles.contains({ subtitle in subtitle.language == info["LanguageName"].string! }) {
                                if let language = info["LanguageName"].string, let downloadLink = info["ZipDownloadLink"].string, let fileName = info["SubFileName"].string, let encoding = info["SubEncoding"].string {
                                    subtitles.append(Subtitle(language: language, fileAddress: downloadLink, fileName: fileName, encoding: encoding))
                                }
                            }
                        }
                        subtitles.sortInPlace({ $0.language < $1.language })
                        dispatch_async(dispatch_get_main_queue(), {
                            completion(subtitles: subtitles)
                        })
                    } else {
                        dispatch_async(dispatch_get_main_queue(), {
                            completion(subtitles: nil)
                        })
                    }
                })
            } else {
                completion(subtitles: nil)
            }
        }
    }
    
    func searchWithFile(movieFile: String, completion: (subtitles: [Subtitle]?) -> Void) {
        if let fh = fileHash(movieFile) {
            self.login { success in
                if success {
                    var params: XMLRPCStructure = ["sublanguageid": "all"]
                    params["moviehash"] = fh.hash
                    params["moviesize"] = fh.size
                    params["tag"] = fh.name
                    let array: XMLRPCArray = [params]
                    let limit: XMLRPCStructure = ["limit": "300"]
                    let queue = dispatch_queue_create("com.popcorn-time.response.queue", DISPATCH_QUEUE_CONCURRENT)
                    AlamofireXMLRPC.request(self.secureBaseURL, methodName: "SearchSubtitles", parameters: [self.token, array, limit], headers: ["User-Agent": self.userAgent]).validate().response(queue: queue, responseSerializer: Request.XMLRPCResponseSerializer(), completionHandler: { response in
                        guard response.result.isSuccess && Int(response.result.value![0]["status"].string!.componentsSeparatedByString(" ").first!)! == 200 else {
                            print("Error is \(response.result.error!)")
                            return
                        }
                        if let response = response.result.value![0]["data"].array {
                            var subtitles = [Subtitle]()
                            for info in response {
                                if !subtitles.contains({ subtitle in subtitle.language == info["LanguageName"].string! }) {
                                    if let language = info["LanguageName"].string, let downloadLink = info["ZipDownloadLink"].string, let fileName = info["SubFileName"].string, let encoding = info["SubEncoding"].string {
                                        subtitles.append(Subtitle(language: language, fileAddress: downloadLink, fileName: fileName, encoding: encoding))
                                    }
                                }
                            }
                            subtitles.sortInPlace({ $0.language < $1.language })
                            dispatch_async(dispatch_get_main_queue(), {
                                completion(subtitles: subtitles)
                            })
                        } else {
                            dispatch_async(dispatch_get_main_queue(), {
                                completion(subtitles: nil)
                            })
                        }
                    })
                } else {
                    completion(subtitles: nil)
                }
            }
        } else {
            print("....")
            completion(subtitles: nil)
        }
        
    }
    
    func cleanSubs() {
        let paths = NSSearchPathForDirectoriesInDomains(.CachesDirectory, .UserDomainMask, true)
        if let cachcesDirectory = paths.first {
            let path = cachcesDirectory.stringByAppendingPathComponent("Subtitles")
            do {
                let subs = try NSFileManager.defaultManager().contentsOfDirectoryAtPath(path)
                for item in subs {
                    try NSFileManager.defaultManager().removeItemAtPath(path.stringByAppendingPathComponent(item))
                }
            } catch {
                
            }
        }
    }
    
}
