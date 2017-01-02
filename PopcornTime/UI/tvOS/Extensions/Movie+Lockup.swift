

import PopcornKit
import ObjectMapper

extension Movie {

    var lockUp: String {
        var string = "<lockup actionID=\"showMovie»\(title.cleaned)»\(id)\">"
        string += "<img style=\"tv-placeholder:movie;\" src=\"\(smallCoverImage ?? "")\" width=\"250\" height=\"375\" />"
        string += "<title style=\"tv-text-highlight-style: marquee-and-show-on-highlight;\">\(title.cleaned)</title>"
        string += "<overlay>" + "\n"
        if WatchedlistManager<Movie>.movie.isAdded(self) {
            string += "<badge src=\"resource://indicator-watched\" class=\"indicator\"/>" + "\n"
        } else if WatchedlistManager<Movie>.movie.currentProgress(self) > 0.0 {
            string += "<progressBar value=\"\(WatchedlistManager<Movie>.movie.currentProgress(self))\" class=\"bar\" />" + "\n"
        }
        string += "</overlay>" + "\n"
        string += "</lockup>"
        return string
    }

}
