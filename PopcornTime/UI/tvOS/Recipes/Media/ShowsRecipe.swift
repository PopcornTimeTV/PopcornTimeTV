

import Foundation
import PopcornKit


class ShowsRecipe: MediaRecipe {
    
    override var filter: String {
        return ShowManager.Filters(rawValue: currentFilter)!.string
    }
    
    override var genre: String {
        return currentGenre == "All" ? "" : " " + currentGenre
    }
    
    override var type: String {
        return "Show"
    }
    
    override var continueWatchingLockup: String {
        return onDeck.map {
            guard let episode = $0 as? Episode else { return "" }
            var xml = "<lockup id=\"continueWatchingLockup\" actionID=\"showShow»\(episode.show.title.cleaned)»\(episode.show.id)\">" + "\n"
            xml +=      "<img src=\"\(episode.largeBackgroundImage ?? "")\" width=\"850\" height=\"350\" />" + "\n"
            xml +=      "<overlay>" + "\n"
            xml +=          "<title class=\"overlayTitle\">\(episode.title)</title>" + "\n"
            xml +=          "<subtitle class=\"overlaySubtitle\">\(episode.show.title): S\(episode.season):E\(episode.episode)</subtitle>" + "\n"
            xml +=          "<progressBar value=\"\(WatchedlistManager<Episode>.episode.currentProgress(episode))\" class=\"bar\" />" + "\n"
            xml +=     "</overlay>" + "\n"
            xml +=  "</lockup>" + "\n"
            return xml
            }.joined(separator: "")
    }
    
    init() {
        super.init(onDeck: WatchedlistManager<Episode>.episode.getOnDeck(), title: "Shows", defaultGenre: ShowManager.Genres.all.rawValue, defaultFilter: ShowManager.Filters.trending.rawValue)
    }
    
}
