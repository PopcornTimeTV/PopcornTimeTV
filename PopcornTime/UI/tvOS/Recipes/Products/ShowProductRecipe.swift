

import TVMLKitchen
import PopcornKit
import ObjectMapper

@objc class ShowProductRecipe: ProductRecipe, RecipeType {

    var season: Int
    var show: Show
    let fanartLogo: String?
    
    override var media: Media {
        return show
    }

    init?(show: Show, currentSeason: Int? = nil, fanart: String?) {
        guard !show.seasonNumbers.isEmpty else { return nil }
        
        self.show = show
        self.fanartLogo = fanart
        
        if let season = currentSeason, show.seasonNumbers.contains(season) {
            self.season = season
        } else if let season = show.latestUnwatchedEpisode()?.season {
            self.season = season
        } else {
            season = show.seasonNumbers.first!
        }
        
        super.init()
    }
    
    override func enableThemeSong() {
        super.enableThemeSong()
        
        if let sid = show.tvdbId, let id = Int(sid) {
            ThemeSongManager.shared.playShowTheme(id)
        }
        
        ActionHandler.shared.showSeason(String(season)) // Refresh the current season's episode when the view controller loads
        
        if let episode = show.latestUnwatchedEpisode(),
            let button = doc?.invokeMethod("getElementById", withArguments: ["resumeButton"]),
            !button.isUndefined {
            let actionID = "chooseQuality»\(Mapper<Torrent>().toJSONString(episode.torrents) ?? "")»\(Mapper<Episode>().toJSONString(episode) ?? "")"
            button.invokeMethod("setAttribute", withArguments: ["actionID", actionID])
        }
    }
    override dynamic var watchlistStatusButtonImage: String {
        return WatchlistManager<Show>.show.isAdded(show) ? "button-remove" : "button-add"
    }
    
    func groupedEpisodes(bySeason season: Int) -> [Episode] {
        return show.episodes.filter({$0.season == season}).sorted(by: {$0.0.episode < $0.1.episode})
    }

    var xmlString: String {
        var xml = "<?xml version=\"1.0\" encoding=\"UTF-8\" ?>"
        xml += "<document>"
        xml += template
        xml += "</document>"
        return xml
    }
    
    var episodeShelf: String {
        var xml = "<header>" + "\n"
        xml += "<title>\(episodeCount)</title>" + "\n"
        xml += "</header>" + "\n"
        xml += "<section>" + "\n"
        xml +=  episodesString + "\n"
        xml += "</section>" + "\n"
        return xml
    }

    var seasonString: String {
        return "Season \(season)"
    }

    var actorsString: String {
        return show.actors.map { "<text>\($0.name)</text>" }.joined(separator: "")
    }

    var genresString: String {
        if let first = show.genres.first {
            var genreString = first
            if show.genres.count > 2 {
                genreString += " & \(show.genres[1])"
            }
            return "\(genreString.capitalized.cleaned)"
        }
        return ""
    }
    
    var playButtonString: String {
        guard let episode = show.latestUnwatchedEpisode() else { return "" }
        
        var xml = "<buttonLockup id=\"resumeButton\" actionID=\"chooseQuality»\(Mapper<Torrent>().toJSONString(episode.torrents)?.cleaned ?? "")»\(Mapper<Episode>().toJSONString(episode)?.cleaned ?? "")\">"
        xml += "<badge src=\"resource://button-play\" />" + "\n"
        xml += "<title>Resume Playing</title>" + "\n"
        xml += "</buttonLockup>" + "\n"
        
        return xml
    }
    
    var bannerString: String {
        if let fanartLogo = fanartLogo {
            return "<img src=\"\(fanartLogo)\" width=\"200\" height=\"200\"/>"
        }
        return "<title>\(show.title.cleaned)</title>" + "\n"
    }

    var episodeCount: String {
        return "\(show.episodes.filter({$0.season == season}).count) Episodes"
    }
    
    var suggestionsString: String {
        guard !show.related.isEmpty else { return "" }
        
        var xml = "<shelf>" + "\n"
        xml +=      "<header>" + "\n"
        xml +=          "<title>Similar Shows</title>" + "\n"
        xml +=      "</header>" + "\n"
        xml +=      "<section>" + "\n"
        xml +=          "\(show.related.map {$0.lockUp.replacingOccurrences(of: "width=\"250\"", with: "width=\"150\"").replacingOccurrences(of: "height=\"375\"", with: "height=\"226\"")}.joined(separator: "\n"))"
        xml +=      "</section>" + "\n"
        xml +=  "</shelf>" + "\n"
        
        return xml
    }
    
    var castString: String {
        if show.actors.isEmpty && show.crew.isEmpty { return "" }
        
        let actors: [String] = show.actors.map {
            var headshot = ""
            if let image = $0.mediumImage {
                headshot = " src=\"\(image)\""
            }
            let name = $0.name.components(separatedBy: " ")
            var string = "<monogramLockup actionID=\"showShowCredits»\($0.name)»\($0.imdbId)\">" + "\n"
            string += "<monogram firstName=\"\(name.first!)\" lastName=\"\(name.last!)\"\(headshot)/>"
            string += "<title>\($0.name.cleaned)</title>" + "\n"
            string += "<subtitle>\($0.characterName.cleaned)</subtitle>" + "\n"
            string += "</monogramLockup>" + "\n"
            return string
        }
        let cast: [String] = show.crew.map {
            var headshot = ""
            if let image = $0.mediumImage {
                headshot = " src=\"\(image)\""
            }
            let name = $0.name.components(separatedBy: " ")
            var string = "<monogramLockup actionID=\"showShowCredits»\($0.name)»\($0.imdbId)\">" + "\n"
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
        var string = "<buttonLockup id =\"watchlistButton\" actionID=\"toggleShowWatchlist»\(Mapper<Show>().toJSONString(show)?.cleaned ?? "")\">\n"
        string += "<badge id =\"watchlistButtonBadge\" src=\"resource://button-{{WATCHLIST_ACTION}}\" />\n"
        string += "<title>Watchlist</title>\n"
        string += "</buttonLockup>"
        return string
    }

    var themeSong: String {
        var s = "<background>\n"
        s += "<audio>\n"
        s += "<asset id=\"tv_theme\" src=\"http://tvthemes.plexapp.com/\(show.tvdbId ?? "").mp3\"/>"
        s += "</audio>\n"
        s += "</background>\n"
        return ""
    }

    var seasonsButtonTitle: String {
        return "<badge src=\"resource://seasons_mask\" width=\"50px\" height=\"37px\"></badge>"
    }
    
    var networkString: String {
        if let network = show.network { return "Watch \(show.title) on \(network)" }
        return ""
    }

    var seasonsButton: String {
        var string = "<buttonLockup actionID=\"showSeasons»\(Mapper<Show>().toJSONString(show)?.cleaned ?? "")»\(Mapper<Episode>().toJSONString(show.episodes)?.cleaned ?? "")\">"
        string += "\(seasonsButtonTitle)"
        string += "<title>Series</title>"
        string += "</buttonLockup>"
        return string
    }

    var episodesString: String {
        let mapped: [String] = show.episodes.filter({$0.season == season}).map {
            var string = "<lockup actionID=\"chooseQuality»\(Mapper<Torrent>().toJSONString($0.torrents)?.cleaned ?? "")»\(Mapper<Episode>().toJSONString($0)?.cleaned ?? "")\">" + "\n"
            string += "<img class=\"placeholder\" src=\"\($0.mediumBackgroundImage ?? "")\" width=\"310\" height=\"175\" />" + "\n"
            string += "<title>\($0.episode). \($0.title.cleaned)</title>" + "\n"
            string += "<overlay class=\"overlayPosition\">" + "\n"
            if WatchedlistManager<Episode>.episode.isAdded($0.id) {
                string += "<badge src=\"resource://overlay-checkmark\" class=\"overlayPosition\"/>" + "\n"
            } else if WatchedlistManager<Episode>.episode.currentProgress($0.id) > 0.0 {
                string += "<progressBar value=\"\(WatchedlistManager<Episode>.episode.currentProgress($0.id))\" />" + "\n"
            }
            string += "</overlay>" + "\n"
            string += "<relatedContent>" + "\n"
            string += "<infoTable>" + "\n"
            string +=   "<header>" + "\n"
            string +=       "<title>\($0.title.cleaned)</title>" + "\n"
            string +=   "</header>" + "\n"
            string +=   "<info>" + "\n"
            string +=       "<header>" + "\n"
            string +=           "<title>" + "\n"
            string +=               "\(DateFormatter.localizedString(from: $0.firstAirDate, dateStyle: .medium, timeStyle: .none))" + "\n"
            if let genre = $0.show.genres.first {
                string +=           "\(genre.capitalized)" + "\n"
            }
            string +=           "</title>" + "\n"
            string +=       "</header>" + "\n"
            string +=   "<description allowsZooming=\"true\" moreLabel=\"more\" actionID=\"showDescription»\($0.title.cleaned)»\($0.summary.cleaned)\">\($0.summary.cleaned)</description>" + "\n"
            string +=   "</info>" + "\n"
            string += "</infoTable>" + "\n"
            string += "</relatedContent>" + "\n"
            string += "</lockup>" + "\n"
            return string
        }
        return mapped.joined(separator: "\n")
    }

    var template: String {
        let file = Bundle.main.url(forResource: "ShowProductRecipe", withExtension: "xml")!
        var xml = try! String(contentsOf: file)
        
        xml = xml.replacingOccurrences(of: "{{TITLE}}", with: show.title.cleaned)
        xml = xml.replacingOccurrences(of: "{{SEASON}}", with: seasonString)
        xml = xml.replacingOccurrences(of: "{{BANNER}}", with: bannerString)
        
        xml = xml.replacingOccurrences(of: "{{GENRES}}", with: genresString)
        xml = xml.replacingOccurrences(of: "{{DESCRIPTION}}", with: show.summary.cleaned)
        xml = xml.replacingOccurrences(of: "{{SHORT_DESCRIPTION}}", with: show.summary.cleaned)
        xml = xml.replacingOccurrences(of: "{{IMAGE}}", with: show.largeCoverImage ?? "")
        xml = xml.replacingOccurrences(of: "{{FANART_IMAGE}}", with: show.largeBackgroundImage ?? "")
        xml = xml.replacingOccurrences(of: "{{YEAR}}", with: show.year.cleaned)
        xml = xml.replacingOccurrences(of: "{{RUNTIME}}", with: (show.runtime ?? "0") + " min")
        
        xml = xml.replacingOccurrences(of: "{{NETWORK}}", with: networkString)
        xml = xml.replacingOccurrences(of: "{{NETWORK_FOOTER}}", with: show.network?.cleaned ?? "TV")
        
        xml = xml.replacingOccurrences(of: "{{SUGGESTIONS}}", with: suggestionsString)
        
        xml = xml.replacingOccurrences(of: "{{WATCH_LIST_BUTTON}}", with: watchlistButton)
        if WatchlistManager<Show>.show.isAdded(show) {
            xml = xml.replacingOccurrences(of: "{{WATCHLIST_ACTION}}", with: "remove")
        } else {
            xml = xml.replacingOccurrences(of: "{{WATCHLIST_ACTION}}", with: "add")
        }
        
        xml = xml.replacingOccurrences(of: "{{EPISODE_SHELF}}", with: episodeShelf)
        
        xml = xml.replacingOccurrences(of: "{{CAST}}", with: castString)
        
        xml = xml.replacingOccurrences(of: "{{SEASONS_BUTTON}}", with: seasonsButton)
        xml = xml.replacingOccurrences(of: "{{RESUME_PLAYING_BUTTON}}", with: playButtonString)
        return xml
    }
}
