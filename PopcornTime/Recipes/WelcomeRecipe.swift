

import TVMLKitchen
import PopcornKit

public struct WelcomeRecipe: RecipeType {

    public let theme = DefaultTheme()
    public let presentationType = PresentationType.Default

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

    public var randomMovieFanart: String {
        return movies[Int(arc4random_uniform(UInt32(movies.count)))].backgroundImage
    }

    public var randomTVShowFanart: String {
        return shows[Int(arc4random_uniform(UInt32(shows.count)))].fanartImage
    }

    /*
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
    */
    
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
        if let file = NSBundle.mainBundle().URLForResource("WelcomeRecipe", withExtension: "xml") {
            do {
                xml = try String(contentsOfURL: file)
                xml = xml.stringByReplacingOccurrencesOfString("{{MOVIES_BACKGROUND}}", withString: randomMovieFanart)
                xml = xml.stringByReplacingOccurrencesOfString("{{TVSHOWS_BACKGROUND}}", withString: randomTVShowFanart)
                /*xml = xml.stringByReplacingOccurrencesOfString("{{KAT_SEARCH}}", withString: katSearch)*/
                

            } catch {
                print("Could not open Catalog template... Something broke open an issue :)")
            }
        }
        return xml
    }

}
