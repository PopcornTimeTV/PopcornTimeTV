

import TVMLKitchen
import PopcornKit
import ObjectMapper

public struct MovieProductRecipe: RecipeType {

    let movie: Movie

    public let theme = DefaultTheme()
    public let presentationType = PresentationType.default

    public init(movie: Movie) {
        self.movie = movie
    }


    public var xmlString: String {
        var xml = "<?xml version=\"1.0\" encoding=\"UTF-8\" ?>"
        xml += "<document>"
        xml += template
        xml += "</document>"
        return xml
    }

    var directorsString: String {
        let directors = movie.crew.filter({ $0.roleType == .director })
        return directors.map { "<text>\($0.name.cleaned)</text>" }.joined(separator: "")
    }

    var actorsString: String {
        return movie.actors.map { "<text>\($0.name.cleaned)</text>" }.joined(separator: "")
    }

    var genresString: String {
        return movie.genres.map { "<text>\($0.capitalized)</text>" }.joined(separator: "")
    }

    func secondsToHoursMinutesSeconds(_ seconds: Int) -> (Int, Int, Int) {
        return (seconds / 3600, (seconds % 3600) / 60, (seconds % 3600) % 60)
    }

    var runtime: String {
        let (hours, minutes, _) = self.secondsToHoursMinutesSeconds(Int(movie.runtime)! * 60)
        return "\(hours) h \(minutes) min"
    }

    var suggestionsString: String {
        let mapped: [String] = movie.related.map {
            var string = "<lockup actionID=\"showMovie»\($0.title.cleaned)»\($0.id)\">" + "\n"
            string += "<img class=\"placeholder\" src=\"\($0.mediumCoverImage ?? "")\" width=\"150\" height=\"226\" />" + "\n"
            string += "<title class=\"hover\">\($0.title.cleaned)</title>" + "\n"
            string += "</lockup>" + "\n"
            return string
        }
        return mapped.joined(separator: "\n")
    }

    var castString: String {
        let actors: [String] = movie.actors.map {
            var headshot = ""
            if let image = $0.mediumImage {
                headshot = " src=\"\(image)\""
            }
            let name = $0.name.components(separatedBy: " ")
            var string = "<monogramLockup actionID=\"showMovieCredits»\($0.name)»\($0.imdbId)\">" + "\n"
            string += "<monogram firstName=\"\(name.first!)\" lastName=\"\(name.last!)\"\(headshot)/>"
            string += "<title>\($0.name.cleaned)</title>" + "\n"
            string += "<subtitle>Actor</subtitle>" + "\n"
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
        let mapped = actors + cast
        return mapped.joined(separator: "\n")
    }

    var watchlistButton: String {
        var string = "<buttonLockup id =\"favoriteButton\" actionID=\"addMovieToWatchlist»\(Mapper<Movie>().toJSONString(movie)?.cleaned ?? "")\">\n"
        string += "<badge id =\"favoriteButtonBadge\" src=\"resource://button-{{WATCHLIST_ACTION}}\" />\n"
        string += "<title>Favourites</title>\n"
        string += "</buttonLockup>"
        return string
    }

    public var template: String {
        var xml = ""
        if let file = Bundle.main.url(forResource: "MovieProductRecipe", withExtension: "xml") {
            do {
                xml = try String(contentsOf: file)
                xml = xml.replacingOccurrences(of: "{{DIRECTORS}}", with: directorsString)
                xml = xml.replacingOccurrences(of: "{{ACTORS}}", with: actorsString)

                xml = xml.replacingOccurrences(of: "{{RUNTIME}}", with: runtime)
                xml = xml.replacingOccurrences(of: "{{TITLE}}", with: movie.title.cleaned)
                xml = xml.replacingOccurrences(of: "{{GENRES}}", with: genresString)
                xml = xml.replacingOccurrences(of: "{{DESCRIPTION}}", with: movie.summary.cleaned)
                xml = xml.replacingOccurrences(of: "{{IMAGE}}", with: movie.largeCoverImage ?? "")
                xml = xml.replacingOccurrences(of: "{{FANART_IMAGE}}", with: movie.largeBackgroundImage ?? "")
                xml = xml.replacingOccurrences(of: "{{YEAR}}", with: String(movie.year))
                xml = xml.replacingOccurrences(of: "{{RATING}}", with: movie.certification.replacingOccurrences(of: "-", with: ""))
                xml = xml.replacingOccurrences(of: "{{STAR_RATING}}", with: String(movie.rating))

                xml = xml.replacingOccurrences(of: "{{YOUTUBE_PREVIEW_CODE}}", with: movie.trailerCode ?? "")

                xml = xml.replacingOccurrences(of: "{{SUGGESTIONS_TITLE}}", with: "Similar Movies")
                xml = xml.replacingOccurrences(of: "{{SUGGESTIONS}}", with: suggestionsString)

                xml = xml.replacingOccurrences(of: "{{CAST}}", with: castString)

                xml = xml.replacingOccurrences(of: "{{WATCH_LIST_BUTTON}}", with: watchlistButton)
                if WatchlistManager<Movie>.movie.isAdded(movie) {
                    xml = xml.replacingOccurrences(of: "{{WATCHLIST_ACTION}}", with: "remove")
                } else {
                    xml = xml.replacingOccurrences(of: "{{WATCHLIST_ACTION}}", with: "add")
                }
                xml = xml.replacingOccurrences(of: "{{MOVIE}}", with: Mapper<Movie>().toJSONString(movie)?.cleaned ?? "")
                xml = xml.replacingOccurrences(of: "{{TORRENTS}}", with: Mapper<Torrent>().toJSONString(movie.torrents)?.cleaned ?? "")
                
            } catch {
                print("Could not open Catalog template")
            }
        }
        return xml
    }

}
