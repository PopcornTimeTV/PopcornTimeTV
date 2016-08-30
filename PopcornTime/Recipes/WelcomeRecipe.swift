

import TVMLKitchen
import PopcornKit

public struct WelcomeRecipe: RecipeType {
    
    public let theme = DefaultTheme()
    public let presentationType = PresentationType.DefaultWithLoadingIndicator
    
    let title: String
    let movies: [Movie]
    let shows: [Show]
    let watchListMovies: [WatchItem]
    let watchListShows: [WatchItem]
    
    init(title: String, movies: [Movie], shows: [Show], watchListMovies: [WatchItem], watchListShows: [WatchItem]) {
        self.title = title
        self.movies = movies
        self.shows = shows
        self.watchListMovies = watchListMovies
        self.watchListShows = watchListShows
    }
    
    init(title: String) {
        self.title = title
        self.movies = []
        self.shows = []
        self.watchListMovies = []
        self.watchListShows = []
    }
    
    public var xmlString: String {
        var xml = "<?xml version=\"1.0\" encoding=\"UTF-8\" ?>"
        xml += "<document>"
        xml += template
        xml += "</document>"
        return xml
    }
    
    public var popularMovies: String {
        let mapped: [String] = movies.map {
            return $0.lockUp
        }
        return mapped.joinWithSeparator("\n")
    }
    
    public var popularShows: String {
        let mapped: [String] = shows.map {
            return $0.lockUp
        }
        return mapped.joinWithSeparator("\n")
    }
    
    public var carousel: String {
        let mapped: [String] = shows.map {
            return $0.carousel
        }
        return mapped.joinWithSeparator("\n")
    }
    
    public var moviesWatchList: String {
        let mapped: [String] = watchListMovies.map {
            var string = "<lockup actionID=\"showMovie»\($0.id)\">"
            string += "<img src=\"\($0.coverImage)\" width=\"250\" height=\"375\" />"
            string += "<title class=\"hover\">\($0.name.cleaned)</title>"
            string += "</lockup>"
            return string
        }
        return mapped.joinWithSeparator("\n")
    }
    
    public var showsWatchList: String {
        let mapped: [String] = watchListShows.map {
            var string = "<lockup actionID=\"showShow»\($0.id)»\($0.slugged)»\($0.tvdbId)\">"
            string += "<img src=\"\($0.coverImage)\" width=\"250\" height=\"375\" />"
            string += "<title class=\"hover\">\($0.name.cleaned)</title>"
            string += "</lockup>"
            return string
        }
        return mapped.joinWithSeparator("\n")
    }
    
    public var randomMovieFanart: String {
        return movies[Int(arc4random_uniform(UInt32(movies.count)))].backgroundImage
    }
    
    public var randomTVShowFanart: String {
        return shows[Int(arc4random_uniform(UInt32(shows.count)))].fanartImage
    }
    
    public var katSearch: String {
        var content = ""
        if let katSearch = NSUserDefaults.standardUserDefaults().objectForKey("KATSearch") as? Bool {
            if katSearch.boolValue {
                content = "<lockup actionID=\"chooseKickassCategory\">"
                content += "<img class=\"round\" src=\"http://i.cubeupload.com/0LUcIF.png\" width=\"548\" height=\"250\"></img>"
                content += "<overlay><title>Kickass Search</title></overlay></lockup>"
            }
        }
        return content
    }
    
    public var randomWatchlistArt: String {
        if watchListShows.count > 0 {
            if let image = watchListShows[Int(arc4random_uniform(UInt32(watchListShows.count)))].fanartImage {
                return image
            } else {
                return watchListShows[Int(arc4random_uniform(UInt32(watchListShows.count)))].coverImage
            }
        }
        
        if watchListMovies.count > 0 {
            if let image = watchListMovies[Int(arc4random_uniform(UInt32(watchListMovies.count)))].fanartImage {
                return image
            } else {
                return watchListMovies[Int(arc4random_uniform(UInt32(watchListMovies.count)))].coverImage
            }
        }
        
        return "https://github.com/PopcornTimeTV/PopcornTimeTV/blob/master/Assets/Watchlist.lsr?raw=true"
        
    }
    
    func buildShelf(title: String, content: String) -> String {
        var shelf = "<shelf><header><title>"
        shelf += title
        shelf += "</title></header><section>"
        shelf += content
        shelf += "</section></shelf>"
        return shelf
    }
    
    public var template: String {
        var xml = ""
        var shelfs = ""
        if let file = NSBundle.mainBundle().URLForResource("WelcomeRecipe", withExtension: "xml") {
            do {
                xml = try String(contentsOfURL: file)
                xml = xml.stringByReplacingOccurrencesOfString("{{MOVIES_BACKGROUND}}", withString: randomMovieFanart)
                xml = xml.stringByReplacingOccurrencesOfString("{{CAROUSEL}}", withString: carousel)
                xml = xml.stringByReplacingOccurrencesOfString("{{TVSHOWS_BACKGROUND}}", withString: randomTVShowFanart)
                xml = xml.stringByReplacingOccurrencesOfString("{{WATCHLIST_BACKGROUND}}", withString: randomWatchlistArt)
                xml = xml.stringByReplacingOccurrencesOfString("{{KAT_SEARCH}}", withString: katSearch)
                
                if popularMovies.characters.count > 10 {
                    shelfs += self.buildShelf("Popular Movies", content: popularMovies)
                }
                if popularShows.characters.count > 10 {
                    shelfs += self.buildShelf("Popular TV Shows", content: popularShows)
                }
                if moviesWatchList.characters.count > 10 {
                    shelfs += self.buildShelf("Movies Watchlist", content: moviesWatchList)
                }
                if showsWatchList.characters.count > 10 {
                    shelfs += self.buildShelf("TV Shows Watchlist", content: showsWatchList)
                }
                xml = xml.stringByReplacingOccurrencesOfString("{{SHELFS}}", withString: shelfs)
            } catch {
                print("Could not open Catalog template")
            }
        }
        return xml
    }
    
}