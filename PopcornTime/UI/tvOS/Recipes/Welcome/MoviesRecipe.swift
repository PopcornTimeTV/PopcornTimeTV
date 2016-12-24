

import TVMLKitchen
import PopcornKit

class MoviesRecipe: RecipeType {
    
    let theme = DefaultTheme()
    let presentationType = PresentationType.defaultWithLoadingIndicator
    
    var currentPage = 0
    var isLoading = false
    var hasNextPage = false
    
    var currentFilter: MovieManager.Filters = .trending
    var currentGenre: MovieManager.Genres = .all
    
    let fetchBlock: (MovieManager.Filters, MovieManager.Genres, Int, @escaping (String?, NSError?) -> Void) -> Void
    var continueWatchingMovies: [Movie]
    
    init(continueWatchingMovies: [Movie] = [],
         fetchBlock: @escaping (MovieManager.Filters, MovieManager.Genres, Int, @escaping (String?, NSError?) -> Void) -> Void)
    {
        self.fetchBlock = fetchBlock
        self.continueWatchingMovies = continueWatchingMovies
        loadNextPage() { _ in
            ActionHandler.shared.serveTabRecipe(self)
        }
    }
    
    var lockUpString: String = ""
    
    var moviesSection: String {
        guard !lockUpString.isEmpty else { return "" }
        let genreString = currentGenre.rawValue.capitalized
        let titleString = currentFilter.string + (genreString == "All" ? "" : " " + genreString)
        
        var xml = "<grid>" + "\n"
        xml +=     "<header>" + "\n"
        xml +=      "<row>" + "\n"
        xml +=          "<title style=\"tv-align: left;\">\(titleString) Movies</title>" + "\n"
        xml +=          "<buttonLockup style=\"tv-align: right; margin: 0  20;\" actionID=\"showMovieFilters»\(currentFilter.rawValue)\">" + "\n"
        xml +=              "<text>Sort</text>" + "\n"
        xml +=          "</buttonLockup>" + "\n"
        xml +=          "<buttonLockup style=\"tv-align: right;\" actionID=\"showMovieGenres»\(currentGenre.rawValue)\">" + "\n"
        xml +=              "<text>Genre</text>" + "\n"
        xml +=          "</buttonLockup>" + "\n"
        xml +=      "</row>" + "\n"
        xml +=  "</header>" + "\n"
        xml +=  "<section>" + "\n"
        xml +=      lockUpString + "\n"
        xml +=  "</section>" + "\n"
        xml += "</grid>" + "\n"
        return xml
    }
    
    var continueWatchingShelf: String {
        guard !continueWatchingMovies.isEmpty else { return "" }
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
        return continueWatchingMovies.map {
            var xml = "<lockup id=\"continueWatchingLockup\"actionID=\"showMovie»\($0.title.cleaned)»\($0.id)\">" + "\n"
            xml += "<img src=\($0.largeBackgroundImage) width=\"850\" height=\"350\" />" + "\n"
            xml += "<overlay>" + "\n"
            xml += "<title>\($0.title)</title>" + "\n"
            xml += "<progressBar value=\"\(WatchedlistManager.movie.currentProgress($0.id))\" />" + "\n"
            xml += "</lockup>" + "\n"
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
        let file = Bundle.main.url(forResource: "MoviesRecipe", withExtension: "xml")!
        
        var xml = try! String(contentsOf: file)
        xml = xml.replacingOccurrences(of: "{{CONTINUE_WATCHING}}", with: continueWatchingShelf)
        xml = xml.replacingOccurrences(of: "{{MOVIES}}", with: moviesSection)
        return xml
    }
    
    func loadNextPage(_ completion: ((String) -> Void)? = nil) {
        guard !isLoading else { return }
        isLoading = true
        hasNextPage = false
        currentPage += 1
        fetchBlock(currentFilter, currentGenre, currentPage, { (media, error) in
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
            
            self.lockUpString += media
            
            completion?(self.continueWatchingShelf + self.moviesSection)
        })
    }
}
