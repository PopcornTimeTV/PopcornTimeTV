

import Foundation

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
        self.itemExistsInWatchList(itemId: item.id, forType: item.type) { exists in
            if exists {
                completion?(added: false)
            } else {
                self.readJSONFile { json in
                    if let json = json {
                        var mutableJson = json
                        mutableJson.append(item.dictionaryRepresentation)
                        self.writeJSONFile(mutableJson)
                        completion?(added: true)
                    } else {
                        var mutableJson = [[String : AnyObject]]()
                        mutableJson.append(item.dictionaryRepresentation)
                        self.writeJSONFile(mutableJson)
                        completion?(added: true)
                    }
                }
            }
        }
    }

    func removeItemFromWatchList(item: WatchItem, completion: ((removed: Bool) -> Void)?) {
        self.readJSONFile { json in
            if let json = json {
                var mutableJson = json
                if let index = json.indexOf({ $0["id"] as? String == item.id && $0["type"] as? String == item.type.rawValue }) {
                    mutableJson.removeAtIndex(index)
                    self.writeJSONFile(mutableJson)
                    completion?(removed: true)
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
                completion?(parsedItems)
            } else {
                completion?([])
            }
        }
    }

    func itemExistsInWatchList(itemId id: String, forType type: ItemType, completion: ((exists: Bool) -> Void)?) {
        self.readJSONFile { json in
            if let json = json {
                if let _ = json.indexOf({ $0["id"] as? String == id && $0["type"] as? String == type.rawValue }) {
                    completion?(exists: true)
                } else {
                    completion?(exists: false)
                }
            } else {
                completion?(exists: false)
            }
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
