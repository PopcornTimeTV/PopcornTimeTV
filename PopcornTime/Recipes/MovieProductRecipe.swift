

import TVMLKitchen
import PopcornKit

public struct MovieProductRecipe: RecipeType {

    let movie: Movie
    let suggestions: [Movie]
    let existsInWatchList: Bool

    public let theme = DefaultTheme()
    public let presentationType = PresentationType.default

    public init(movie: Movie, suggestions: [Movie], existsInWatchList: Bool) {
        self.movie = movie
        self.suggestions = suggestions
        self.existsInWatchList = existsInWatchList
    }

    public var xmlString: String {
        var xml = "<?xml version=\"1.0\" encoding=\"UTF-8\" ?>"
        xml += "<document>"
        xml += template
        xml += "</document>"
        return xml
    }

    var directorsString: String {
        let directors = movie.crew.filter({ $0.roleType == .Director })
        return directors.map { "<text>\($0.name.cleaned)</text>" }.joined(separator: "")
    }

    var actorsString: String {
        return movie.actors.map { "<text>\($0.name.cleaned)</text>" }.joined(separator: "")
    }

    var genresString: String {
        if movie.genres.count == 2 {
            return "<text>\(movie.genres[0]) &amp; \(movie.genres[1])</text>"
        } else {
            return "<text>\(movie.genres.first!)</text>"
        }
    }

    func secondsToHoursMinutesSeconds(_ seconds: Int) -> (Int, Int, Int) {
        return (seconds / 3600, (seconds % 3600) / 60, (seconds % 3600) % 60)
    }

    var runtime: String {
        let (hours, minutes, _) = self.secondsToHoursMinutesSeconds(Int(movie.runtime)! * 60)
        return "\(hours) h \(minutes) min"
    }

    var suggestionsString: String {
        let mapped: [String] = suggestions.map {
            var string = "<lockup actionID=\"showMovie»\($0.id)\">" + "\n"
            string += "<img src=\"\($0.mediumCoverImage ?? "")\" width=\"150\" height=\"226\" />" + "\n"
            string += "<title class=\"hover\">\($0.title.cleaned)</title>" + "\n"
            string += "</lockup>" + "\n"
            return string
        }
        return mapped.joined(separator: "\n")
    }

    var castString: String {
        let actors: [String] = movie.actors.map {
            var headshot = ""
            if $0.mediumImage != "http://62.210.81.37/assets/images/actors/default_avatar.jpg" {
                headshot = " src=\"\($0.mediumImage)\""
            }
            let name = $0.name.components(separatedBy: " ")
            var string = "<monogramLockup actionID=\"showActor»\($0.name)\">" + "\n"
            string += "<monogram firstName=\"\(name.first!)\" lastName=\"\(name.last!)\"\(headshot)/>"
            string += "<title>\($0.name.cleaned)</title>" + "\n"
            string += "<subtitle>Actor</subtitle>" + "\n"
            string += "</monogramLockup>" + "\n"
            return string
        }
        let directors: [String] = movie.crew.filter({ $0.roleType == .Director }).map {
            var headshot = ""
            if $0.mediumImage != "http://62.210.81.37/assets/images/directors/default_avatar.jpg" {
                headshot = " src=\"\($0.mediumImage)\""
            }
            let name = $0.name.components(separatedBy: " ")
            var string = "<monogramLockup actionID=\"showDirector»\($0.name)\">" + "\n"
            string += "<monogram firstName=\"\(name.first!)\" lastName=\"\(name.last!)\"\(headshot)/>"
            string += "<title>\($0.name.cleaned)</title>" + "\n"
            string += "<subtitle>Director</subtitle>" + "\n"
            string += "</monogramLockup>" + "\n"
            return string
        }
        let mapped = actors + directors
        return mapped.joined(separator: "\n")
    }

    var watchlistButton: String {
        var string = "<buttonLockup id =\"favoriteButton\" actionID=\"addWatchlist»\(movie.id)»\(movie.title.cleaned)»movie»\(movie.largeCoverImage)»\(movie.largeBackgroundImage)»\(movie.id)»»\(movie.slug)\">\n"
        string += "<badge id =\"favoriteButtonBadge\" src=\"resource://button-{{WATCHLIST_ACTION}}\" />\n"
        string += "<title>Favourites</title>\n"
        string += "</buttonLockup>"
        return string
    }

    var torrentHash: String {
        let filteredTorrents = movie.torrents.filter {
            $0.quality == "720p"
        }

        if let first = filteredTorrents.first {
            return first.hash
        } else if let last = movie.torrents.last {
            return last.hash
        }

        return ""
    }


    var torrents: String {
        let filteredTorrents: [String] = movie.torrents.map { torrent in
            return "quality=\(torrent.quality)&hash=\(torrent.hash)"
        }
        return filteredTorrents.joined(separator: "•")
    }

    public var template: String {
        var xml = ""
        if let file = Bundle.main.url(forResource: "MovieProductRecipe", withExtension: "xml") {
            do {
                xml = try String(contentsOf: file)
                xml = xml.replacingOccurrences(of: "{{DIRECTORS}}", with: directorsString)
                xml = xml.replacingOccurrences(of: "{{ACTORS}}", with: actorsString)
                
                xml = xml.replacingOccurrences(of: "{{TOMATO_CRITIC_RATING}}", with: movie.rating <= 59 ? "splat" : "fresh")
                xml = xml.replacingOccurrences(of: "{{TOMATO_CRITIC_SCORE}}", with: "\(movie.rating)")

                xml = xml.replacingOccurrences(of: "{{RUNTIME}}", with: runtime)
                xml = xml.replacingOccurrences(of: "{{TITLE}}", with: movie.title.cleaned)
                xml = xml.replacingOccurrences(of: "{{GENRES}}", with: genresString)
                xml = xml.replacingOccurrences(of: "{{DESCRIPTION}}", with: movie.summary?.cleaned ?? "")
                xml = xml.replacingOccurrences(of: "{{SHORT_DESCRIPTION}}", with: movie.summary?.cleaned ?? "")
                xml = xml.replacingOccurrences(of: "{{IMAGE}}", with: movie.largeCoverImage ?? "")
                xml = xml.replacingOccurrences(of: "{{BACKGROUND_IMAGE}}", with: movie.largeBackgroundImage ?? "")
                xml = xml.replacingOccurrences(of: "{{YEAR}}", with: String(movie.year))
                xml = xml.replacingOccurrences(of: "{{RATING}}", with: movie.certification.replacingOccurrences(of: "-", with: ""))
                xml = xml.replacingOccurrences(of: "{{STAR_RATING}}", with: String(movie.rating))
                xml = xml.replacingOccurrences(of: "{{AIR_DATE_TIME}}", with: "")

                xml = xml.replacingOccurrences(of: "{{YOUTUBE_PREVIEW_URL}}", with: movie.trailer ?? "")

                xml = xml.replacingOccurrences(of: "{{SUGGESTIONS_TITLE}}", with: "Similar Movies")
                xml = xml.replacingOccurrences(of: "{{SUGGESTIONS}}", with: suggestionsString)

                xml = xml.replacingOccurrences(of: "{{CAST}}", with: castString)

                xml = xml.replacingOccurrences(of: "{{WATCH_LIST_BUTTON}}", with: watchlistButton)
                if existsInWatchList {
                    xml = xml.replacingOccurrences(of: "{{WATCHLIST_ACTION}}", with: "rated")
                } else {
                    xml = xml.replacingOccurrences(of: "{{WATCHLIST_ACTION}}", with: "rate")
                }
                xml = xml.replacingOccurrences(of: "{{MOVIE_ID}}", with: movie.id)
                xml = xml.replacingOccurrences(of: "{{TYPE}}", with: "movie")

                xml = xml.replacingOccurrences(of: "{{IMDBID}}", with: movie.id)
                xml = xml.replacingOccurrences(of: "{{TORRENTS}}", with: torrents.cleaned)
            } catch {
                print("Could not open Catalog template")
            }
        }
        return xml
    }

}
