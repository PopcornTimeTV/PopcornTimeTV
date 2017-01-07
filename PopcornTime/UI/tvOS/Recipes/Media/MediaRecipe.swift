

import TVMLKitchen
import PopcornKit
import ObjectMapper


protocol MediaRecipeDelegate: class {
    func load(page: Int, filter: String, genre: String, completion: @escaping (String?, NSError?) -> Void)
}

@objc class MediaRecipe: NSObject, RecipeType, MediaRecipeJSExports {
    
    weak var delegate: MediaRecipeDelegate?
    let title: String
    
    var currentPage = 0
    
    var currentFilter: String
    var currentGenre: String
    
    var onDeck: [Media]
    
    // MARK: MediaRecipeJSExports
    
    dynamic var isLoading = false
    dynamic var hasNextPage = false
    dynamic var doc: JSValue?
    var collectionList: JSValue? {
        return doc?.invokeMethod("getElementsByTagName", withArguments: ["collectionList"]).invokeMethod("item", withArguments: [0])
    }
    
    func toggleWatched(_ actionID: String) {
        guard let json = actionID.components(separatedBy: "»")[safe: 1],
            let id = Mapper<Movie>().map(JSONString: json)?.id else { return } // Only movies supported
        WatchedlistManager<Movie>.movie.toggle(id)
    }
    
    
    init(onDeck: [Media] = [], title: String, defaultGenre: String, defaultFilter: String) {
        self.onDeck = onDeck
        self.currentGenre = defaultGenre
        self.currentFilter = defaultFilter
        self.title = title
    }
    
    var lockup: String = ""
    var filter: String { fatalError("Must be overridden") }
    var genre: String { fatalError("Must be overridden") }
    var type: String { fatalError("Must be overridden") }
    
    var mediaSection: String {
        guard !lockup.isEmpty else { return "" }
        
        var xml = "<grid>" + "\n"
        xml +=     "<header>" + "\n"
        xml +=      "<row>" + "\n"
        xml +=          "<title style=\"tv-align: left;\">\(filter + genre + " " + title)</title>" + "\n"
        xml +=          "<buttonLockup style=\"tv-align: right; margin: 0  20;\" actionID=\"show\(type)Filters»\(currentFilter)\">" + "\n"
        xml +=              "<text>Sort</text>" + "\n"
        xml +=          "</buttonLockup>" + "\n"
        xml +=          "<buttonLockup style=\"tv-align: right;\" actionID=\"show\(type)Genres»\(currentGenre)\">" + "\n"
        xml +=              "<text>Genre</text>" + "\n"
        xml +=          "</buttonLockup>" + "\n"
        xml +=      "</row>" + "\n"
        xml +=  "</header>" + "\n"
        xml +=  "<section>" + "\n"
        xml +=      lockup + "\n"
        xml +=  "</section>" + "\n"
        xml += "</grid>" + "\n"
        return xml
    }
    
    var continueWatchingShelf: String {
        guard !onDeck.isEmpty else { return "" }
        var xml = "<shelf>" + "\n"
        xml +=      "<header>" + "\n"
        xml +=          "<title>Continue Watching</title>" + "\n"
        xml +=      "</header>" + "\n"
        xml +=      "<section>" + "\n"
        xml +=          continueWatchingLockup
        xml +=      "</section>" + "\n"
        xml +=  "</shelf>" + "\n"
        return xml
    }
    
    var continueWatchingLockup: String { fatalError("Must be overridden") }
    
    var xmlString: String {
        var xml = "<?xml version=\"1.0\" encoding=\"UTF-8\" ?>"
        xml += "<document>"
        xml += template
        xml += "</document>"
        return xml
    }
    
    var template: String {
        let file = Bundle.main.url(forResource: "MediaRecipe", withExtension: "xml")!
        
        var xml = try! String(contentsOf: file)
        xml = xml.replacingOccurrences(of: "{{CONTINUE_WATCHING}}", with: continueWatchingShelf)
        xml = xml.replacingOccurrences(of: "{{MEDIA}}", with: mediaSection)
        xml = xml.replacingOccurrences(of: "{{TITLE}}", with: title)
        return xml
    }
    
    @nonobjc func loadNextPage(_ completion: @escaping (String) -> Void) {
        guard !isLoading else { return }
        isLoading = true
        hasNextPage = false
        currentPage += 1
        
        delegate?.load(page: currentPage, filter: currentFilter, genre: currentGenre) { (media, error) in
            self.isLoading = false
            
            guard let media = media else {
                guard let error = error else { return }
                let backgroundView = ErrorBackgroundView()
                backgroundView.setUpView(error: error)
                Kitchen.serve(xmlString: backgroundView.xmlString, type: .tab)
                return
            }
            
            if !media.isEmpty {
                self.hasNextPage = true
            }
            
            self.lockup += media
            
            completion(self.continueWatchingShelf + self.mediaSection)
        }
    }
    
    // Completion parameter must be JSValue as swift closures cannot be cast properly in functions.
    internal func loadNextPage(_ completion: JSValue) {
        loadNextPage { (data) in
            completion.call(withArguments: [data])
        }
    }
    
    func filterWasPicked(_ filter: String, _ completion: @escaping (String) -> Void) {
        currentFilter = filter
        currentPage = 0
        lockup = ""
        
        loadNextPage(completion)
    }
    
    func genreWasPicked(_ genre: String, _ completion: @escaping (String) -> Void) {
        currentGenre = genre
        currentPage = 0
        lockup = ""
        
        loadNextPage(completion)
    }
}
