

import Foundation
import PopcornKit
import ObjectMapper

public enum ItemType: String {
    case Movie = "movie"
    case Show = "show"
}

public struct WatchItem {
    var name: String!
    var id: String!
    var coverImage: String!
    var fanartImage: String!
    var imdbId: String!
    var tvdbId: String!
    var type: ItemType!
    var slugged: String!
    
    var dictionaryRepresentation = [String : AnyObject]()
    
    init(name: String, id: String, coverImage: String, fanartImage: String, type: String, imdbId: String, tvdbId: String, slugged: String) {
        self.name = name
        self.id = id
        self.coverImage = coverImage
        self.fanartImage = fanartImage
        self.type = ItemType(rawValue: type)
        self.imdbId = imdbId
        self.tvdbId = tvdbId
        self.slugged = slugged
        
        self.dictionaryRepresentation = [
            "name": self.name,
            "id": self.id,
            "coverImage": self.coverImage,
            "fanartImage": self.fanartImage,
            "type": self.type.rawValue,
            "imdbId": self.imdbId,
            "tvdbId": self.tvdbId,
            "slugged": self.slugged
        ]
    }
    
    init(dictionary: [String : AnyObject]) {
        if let value = dictionary["name"] as? String {
            self.name = value
        }
        
        if let value = dictionary["id"] as? String {
            self.id = value
        }
        
        if let value = dictionary["coverImage"] as? String {
            self.coverImage = value
        }
        
        if let value = dictionary["fanartImage"] as? String {
            self.fanartImage = value
        }
        
        if let value = dictionary["type"] as? String {
            self.type = ItemType(rawValue: value)
        }
        
        if let value = dictionary["imdbId"] as? String {
            self.imdbId = value
        }
        
        if let value = dictionary["tvdbId"] as? String {
            self.tvdbId = value
        }
        
        if let value = dictionary["slugged"] as? String {
            self.slugged = value
        }
    }
}

public class WatchlistManager {
    
    class func sharedManager() -> WatchlistManager {
        struct Struct {
            static let Instance = WatchlistManager()
        }
        
        return Struct.Instance
    }
    
    init() {
        
    }
    
    // MARK: Public parts
    
    func addItemToWatchList(item: WatchItem, completion: ((added: Bool) -> Void)?) {
        self.itemExistsInWatchList(itemId: item.imdbId, forType: item.type) { exists in
            if exists || TraktTVAPI.sharedManager().isFavourited(item.imdbId){
                completion?(added: false)
            } else { // the item does not exist in either list trakt or our own, so let's add it
                self.readJSONFile { json in
                    if let json = json {
                        if TraktTVAPI.sharedManager().userLoaded(){ //do we use trakt? if yes we will add it to that list only
                            TraktTVAPI.sharedManager().getTraktMetadata(withName: item.slugged,type: item.type == .Movie ? .  Movies : .Shows) { traktID in
                                if traktID != nil {
                                    TraktTVAPI.sharedManager().addToWatchlist(withType: item.type == .Movie ? .  Movies : .Shows, itemID: traktID!,completion: { result in
                                        completion?(added: result)
                                        return
                                        },imdbID: item.imdbId)
                                }else{
                                    completion?(added: false)
                                    return
                                }
                                
                            }
                        }else{ // if we don't use trakt we will add it to our own!
                            var mutableJson = json
                            mutableJson.append(item.dictionaryRepresentation)
                            self.writeJSONFile(mutableJson)
                            completion?(added: true)
                            return
                        }
                    } else if TraktTVAPI.sharedManager().userLoaded(){ //we don't use our own list? let's see if we use trakt
                        // we do so let's add it there
                        TraktTVAPI.sharedManager().getTraktMetadata(withName: item.slugged,type: item.type == .Movie ? .  Movies : .Shows) { traktID in
                            if traktID != nil {
                                TraktTVAPI.sharedManager().addToWatchlist(withType: item.type == .Movie ? .  Movies : .Shows, itemID: traktID!,completion: { result in
                                    completion?(added: result)
                                    return
                                    },imdbID: item.imdbId)
                            }else{
                                completion?(added: false)
                                return
                            }
                            
                        }
                    }else{
                        completion?(added: false)
                    }
                    
                    
                }
                
                
            }
        }
        
    }
    
    func removeItemFromWatchList(item: WatchItem, completion: ((removed: Bool) -> Void)?) {
        self.readJSONFile { json in
            if let json = json { //do we use our own favourite's list?
                var mutableJson = json // we do
                if TraktTVAPI.sharedManager().userLoaded(){ // do we use trakt, then we will only need to remove it from there
                    TraktTVAPI.sharedManager().getTraktMetadata(withName: item.slugged,type: item.type == .Movie ? .  Movies : .Shows){ traktID in
                        if traktID != nil{
                            TraktTVAPI.sharedManager().removeFromWatchlist(withType: item.type == .Movie ? .Movies : .Shows, itemID: traktID!, imdbID: item.imdbId){ result in
                                completion?(removed: result)
                                return
                            }
                        }else{
                            completion?(removed: false)
                            return
                        }
                    }
                if let index = json.indexOf({ $0["imdbId"] as? String == item.imdbId && $0["type"] as? String == item.type.rawValue }) { // if we only use our own favourite implementation, we will remove it from there only!
                        mutableJson.removeAtIndex(index)
                        self.writeJSONFile(mutableJson)
                        completion?(removed: true)
                        return
                    }
                }
            } else if TraktTVAPI.sharedManager().userLoaded(){ // we don't use our own implementation! how about trakt?
                //we use trakt! we will add it remove it from there then!
                    TraktTVAPI.sharedManager().getTraktMetadata(withName: item.slugged,type: item.type == .Movie ? .  Movies : .Shows){ traktID in
                        if traktID != nil{
                            TraktTVAPI.sharedManager().removeFromWatchlist(withType: item.type == .Movie ? .Movies : .Shows, itemID: traktID!, imdbID: item.imdbId){ result in
                                completion?(removed: result)
                                return
                            }
                        }else{
                            completion?(removed: false)
                            return
                        }
                    }
                }
        }
        
    }
    func fetchWatchListItems(forType type: ItemType, completion: (([WatchItem]) -> Void)?) {
        self.readJSONFile { json in
            if let json = json {
                var parsedItems = [WatchItem]()
                for item in json {
                    if let itemType = item["type"] as? String {
                        if itemType == type.rawValue {
                            parsedItems.append(WatchItem(dictionary: item))
                        }
                    }
                }
                if(TraktTVAPI.sharedManager().userLoaded()){
                    TraktTVAPI.sharedManager().getWatched(forType: type == .Movie ? .Movies : .Shows) { results in
                        if let results = results{
                            for result in results{
                                if(type == .Movie){
                                    let movie = result as! Movie
                                    parsedItems.append(WatchItem(name: movie.title, id: movie.imdbId, coverImage: movie.mediumCoverImage, fanartImage: movie.smallCoverImage, type: "movie", imdbId: movie.imdbId, tvdbId: "", slugged: movie.slug))
                                }else{
                                    let show = result as! Show
                                    parsedItems.append(WatchItem(name: show.title, id: show.id, coverImage: show.posterImage, fanartImage: show.fanartImage, type: "show", imdbId: "", tvdbId: String(show.tvdbId), slugged: show.slug))
                                }
                            }
                        }
                        completion?(parsedItems)
                        return
                        
                    }
                }
            } else if(TraktTVAPI.sharedManager().userLoaded()) {
                var parsedItems = [WatchItem]()
                TraktTVAPI.sharedManager().getWatched(forType: type == .Movie ? .Movies : .Shows) { results in
                    if let results = results{
                        for result in results{
                            if(type == .Movie){
                                let movie = result as! Movie
                                parsedItems.append(WatchItem(name: movie.title, id: movie.imdbId, coverImage: movie.mediumCoverImage, fanartImage: movie.smallCoverImage, type: "movie", imdbId: movie.imdbId, tvdbId: "", slugged: movie.slug))
                            }else{
                                let show = result as! Show
                                parsedItems.append(WatchItem(name: show.title, id: show.id, coverImage: show.posterImage, fanartImage: show.fanartImage, type: "show", imdbId: "", tvdbId: String(show.tvdbId), slugged: show.slug))
                            }
                        }
                    }
                    completion?(parsedItems)
                    return
                    
                }
            } else {
                completion?([])
                return
            }
        }
    }
    
    func itemExistsInWatchList(itemId id: String, forType type: ItemType, completion: ((exists: Bool) -> Void)?) {
        var result = false
        self.readJSONFile { json in
            if let json = json {
                if let _ = json.indexOf({ $0["imdbId"] as? String == id && $0["type"] as? String == type.rawValue }) {
                    result = true
                } else {
                    result = false
                }
            } else if(TraktTVAPI.sharedManager().userLoaded()){
                if TraktTVAPI.sharedManager().isFavourited(id){
                    completion?(exists:true)
                    return
                }
                completion?(exists:result)
                return
            }else{
                completion?(exists: result)
                return
            }
        }
        if(TraktTVAPI.sharedManager().userLoaded()){
            if TraktTVAPI.sharedManager().isFavourited(id){
                completion?(exists:true)
                return
            }
            completion?(exists:false)
        }
    }
    
    // MARK: Private parts
    
    func readJSONFile(completion: ((json: [[String : AnyObject]]?) -> Void)?) {
        if let json = NSUserDefaults.standardUserDefaults().objectForKey("Watchlist") as? [[String : AnyObject]] {
            completion?(json: json)
        } else {
            completion?(json: nil)
        }
    }
    
    func writeJSONFile(json: [[String : AnyObject]]) {
        NSUserDefaults.standardUserDefaults().setObject(json, forKey: "Watchlist")
    }
}
