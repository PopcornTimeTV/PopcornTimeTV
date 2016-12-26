

import TVMLKitchen
import PopcornKit


protocol MediaRecipeDelegate: class {
    func load(page: Int, filter: String, genre: String, completion: @escaping (String?, NSError?) -> Void)
}

class MediaRecipe: RecipeType {
    
    let theme = DefaultTheme()
    let presentationType = PresentationType.defaultWithLoadingIndicator
    
    weak var delegate: MediaRecipeDelegate?
    let title: String
    
    var currentPage = 0
    var isLoading = false
    var hasNextPage = false
    
    var currentFilter: String = ""
    var currentGenre: String = ""

    var continueWatchingMedia: [Media]
    
    init(continueWatchingMedia: [Media] = [], title: String, defaultGenre: String, defaultFilter: String) {
        self.continueWatchingMedia = continueWatchingMedia
        self.currentGenre = defaultGenre
        self.currentFilter = defaultFilter
        self.title = title
    }
    
    var lockup: String = ""
    var filter: String { fatalError("Must be overridden") }
    var genre: String { fatalError("Must be overridden") }
    var type: String { fatalError("Must be overridden") }
    
    var watchedlistManager: WatchedlistManager { fatalError("Must be overridden") }
    
    var mediaSection: String {
        guard !lockup.isEmpty else { return "" }
        
        var xml = "<grid>" + "\n"
        xml +=     "<header>" + "\n"
        xml +=      "<row>" + "\n"
        xml +=          "<title style=\"tv-align: left;\">\(filter + " " + genre + " " + title)</title>" + "\n"
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
        guard !continueWatchingMedia.isEmpty else { return "" }
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
    
    var continueWatchingLockup: String {
        return continueWatchingMedia.map {
            var xml = "<lockup id=\"continueWatchingLockup\"actionID=\"show\(type)»\($0.title.cleaned)»\($0.id)\">" + "\n"
            xml +=      "<img src=\($0.largeBackgroundImage) width=\"850\" height=\"350\" />" + "\n"
            xml +=      "<overlay>" + "\n"
            xml +=          "<title>\($0.title)</title>" + "\n"
            xml +=          "<progressBar value=\"\(watchedlistManager.currentProgress($0.id))\" />" + "\n"
             xml +=     "</overlay>" + "\n"
            xml +=  "</lockup>" + "\n"
            return xml
        }.joined(separator: "")
    }
    
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
    
    func loadNextPage(_ completion: ((String) -> Void)? = nil) {
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
            
            completion?(self.continueWatchingShelf + self.mediaSection)
        }
    }
}
