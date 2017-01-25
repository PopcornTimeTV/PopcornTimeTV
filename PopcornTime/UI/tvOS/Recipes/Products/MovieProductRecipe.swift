

import TVMLKitchen
import PopcornKit
import ObjectMapper

@objc class MovieProductRecipe: ProductRecipe, RecipeType {
    
    var movie: Movie
    let fanartLogo: String?
    
    override var media: Media {
        return movie
    }

    init(movie: Movie, fanart: String?) {
        self.movie = movie
        self.fanartLogo = fanart
        super.init()
    }
    
    override func enableThemeSong() {
        super.enableThemeSong()
        
        ThemeSongManager.shared.playMovieTheme(movie.title)
        
        updateWatchedButton()
    }
    
    override dynamic var watchlistStatusButtonImage: String {
        return WatchlistManager<Movie>.movie.isAdded(movie) ? "button-remove" : "button-add"
    }
    
    override dynamic var watchedStatusButtonImage: String {
        return WatchedlistManager<Movie>.movie.isAdded(movie.id) ? "button-watched" : "button-unwatched"
    }


    var xmlString: String {
        var xml = "<?xml version=\"1.0\" encoding=\"UTF-8\" ?>"
        xml += "<document>"
        xml += template
        xml += "</document>"
        return xml
    }

    var directorsString: String {
        let directors = movie.crew.filter({ $0.roleType == .director })
        return directors.map { "<text>\($0.name.cleaned)</text>" }.joined(separator: "\n")
    }

    var actorsString: String {
        return movie.actors.map { "<text>\($0.name.cleaned)</text>" }.joined(separator: "\n")
    }

    var genresString: String {
        if let first = movie.genres.first {
            var genreString = first
            if movie.genres.count > 2 {
                genreString += " & \(movie.genres[1])"
            }
            return "<text>\(genreString.capitalized.cleaned) </text>"
        }
        return ""
    }

    var bannerString: String {
        if let fanartLogo = fanartLogo {
            return "<img src=\"\(fanartLogo)\" width=\"200\" height=\"200\"/>"
        }
        return "<title>\(movie.title.cleaned)</title>" + "\n"
    }

    func secondsToHoursMinutesSeconds(_ seconds: Int) -> (Int, Int, Int) {
        return (seconds / 3600, (seconds % 3600) / 60, (seconds % 3600) % 60)
    }

    var runtime: String {
        if let runtime = Int(currentItem.runtime) {
            let (hours, minutes, _) = secondsToHoursMinutesSeconds(runtime * 60)
            
            let formatted = "\(hours) h"
            
            return minutes > 0 ? formatted + " \(minutes) min" : formatted
        }
        return ""
    }

    var suggestionsString: String {
        guard !movie.related.isEmpty else { return "" }
        
        var xml = "<shelf>" + "\n"
        xml +=      "<header>" + "\n"
        xml +=          "<title>Similar Movies</title>" + "\n"
        xml +=      "</header>" + "\n"
        xml +=      "<section>" + "\n"
        xml +=          "\(movie.related.map {$0.lockUp.replacingOccurrences(of: "width=\"250\"", with: "width=\"150\"").replacingOccurrences(of: "height=\"375\"", with: "height=\"226\"")}.joined(separator: "\n"))"
        xml +=      "</section>" + "\n"
        xml +=  "</shelf>" + "\n"
        
        return xml
    }

    var castString: String {
        if movie.actors.isEmpty && movie.crew.isEmpty { return "" }
        
        let actors: [String] = movie.actors.map {
            var headshot = ""
            if let image = $0.mediumImage {
                headshot = " src=\"\(image)\""
            }
            let name = $0.name.components(separatedBy: " ")
            var string = "<monogramLockup actionID=\"showMovieCredits»\($0.name)»\($0.imdbId)\">" + "\n"
            string += "<monogram firstName=\"\(name.first!)\" lastName=\"\(name.last!)\"\(headshot)/>"
            string += "<title>\($0.name.cleaned)</title>" + "\n"
            string += "<subtitle>\($0.characterName.cleaned)</subtitle>" + "\n"
            string += "</monogramLockup>" + "\n"
            return string
        }
        let cast: [String] = movie.crew.map {
            var headshot = ""
            if let image = $0.mediumImage {
                headshot = " src=\"\(image)\""
            }
            let name = $0.name.components(separatedBy: " ")
            var string = "<monogramLockup actionID=\"showMovieCredits»\($0.name)»\($0.imdbId)\">" + "\n"
            string += "<monogram firstName=\"\(name.first!)\" lastName=\"\(name.last!)\"\(headshot)/>"
            string += "<title>\($0.name.cleaned)</title>" + "\n"
            string += "<subtitle>\($0.job.cleaned)</subtitle>" + "\n"
            string += "</monogramLockup>" + "\n"
            return string
        }
        
        let lockup = (actors + cast).joined(separator: "\n")
        
        var xml = "<shelf>" + "\n"
        xml +=      "<header>" + "\n"
        xml +=          "<title>Cast and Crew</title>" + "\n"
        xml +=      "</header>" + "\n"
        xml +=      "<section>" + "\n"
        xml +=          "\(lockup)" + "\n"
        xml +=      "</section>" + "\n"
        xml +=  "</shelf>" + "\n"
        
        
        return xml
    }

    var watchlistButton: String {
        var string = "<buttonLockup id =\"watchlistButton\" actionID=\"toggleMovieWatchlist»\(Mapper<Movie>().toJSONString(movie)?.cleaned ?? "")\">\n"
        string += "<badge id =\"watchlistButtonBadge\" src=\"resource://\(watchlistStatusButtonImage)\" />\n"
        string += "<title>Watchlist</title>\n"
        string += "</buttonLockup>"
        return string
    }
    
    var watchedButton: String {
        var string = "<buttonLockup id =\"watchedButton\" actionID=\"toggleMovieWatched»\(Mapper<Movie>().toJSONString(movie)?.cleaned ?? "")\">\n"
        string += "<badge id =\"watchedButtonBadge\" src=\"resource://\(watchedStatusButtonImage)\" />\n"
        string += "<title>Watched</title>\n"
        string += "</buttonLockup>"
        return string
    }

    var template: String {
        let file = Bundle.main.url(forResource: "MovieProductRecipe", withExtension: "xml")!
        var xml = try! String(contentsOf: file)
        xml = xml.replacingOccurrences(of: "{{DIRECTORS}}", with: directorsString)
        xml = xml.replacingOccurrences(of: "{{ACTORS}}", with: actorsString)
        xml = xml.replacingOccurrences(of: "{{BANNER}}", with: bannerString)
        
        xml = xml.replacingOccurrences(of: "{{RUNTIME}}", with: runtime)
        xml = xml.replacingOccurrences(of: "{{TITLE}}", with: movie.title.cleaned)
        xml = xml.replacingOccurrences(of: "{{GENRES}}", with: genresString)
        xml = xml.replacingOccurrences(of: "{{DESCRIPTION}}", with: movie.summary.cleaned)
        xml = xml.replacingOccurrences(of: "{{IMAGE}}", with: movie.largeCoverImage ?? "")
        xml = xml.replacingOccurrences(of: "{{FANART_IMAGE}}", with: movie.largeBackgroundImage ?? "")
        xml = xml.replacingOccurrences(of: "{{YEAR}}", with: movie.year)
        xml = xml.replacingOccurrences(of: "{{RATING}}", with: movie.certification.replacingOccurrences(of: "-", with: "").lowercased())
        xml = xml.replacingOccurrences(of: "{{RATING_FOOTER}}", with: movie.certification.replacingOccurrences(of: "-", with: " "))
        xml = xml.replacingOccurrences(of: "{{STAR_RATING}}", with: String(movie.rating))
        
        xml = xml.replacingOccurrences(of: "{{YOUTUBE_PREVIEW_CODE}}", with: movie.trailerCode ?? "")
        
        xml = xml.replacingOccurrences(of: "{{SUGGESTIONS}}", with: suggestionsString)
        
        xml = xml.replacingOccurrences(of: "{{CAST}}", with: castString)
        
        xml = xml.replacingOccurrences(of: "{{WATCH_LIST_BUTTON}}", with: watchlistButton)
        xml = xml.replacingOccurrences(of: "{{WATCHED_LIST_BUTTON}}", with: watchedButton)
        xml = xml.replacingOccurrences(of: "{{PLAY_BUTTON_TITLE}}", with: WatchedlistManager<Movie>.movie.currentProgress(movie.id) > 0.0 ? "Resume Playing" : "Play")
        
        xml = xml.replacingOccurrences(of: "{{MOVIE}}", with: Mapper<Movie>().toJSONString(movie)?.cleaned ?? "")
        xml = xml.replacingOccurrences(of: "{{TORRENTS}}", with: Mapper<Torrent>().toJSONString(movie.torrents)?.cleaned ?? "")
        return xml
    }

}
