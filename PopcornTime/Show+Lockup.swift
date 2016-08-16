

import PopcornKit

extension Show {

    var lockUp: String {
        var string = "<lockup actionID=\"showShow»\(id)»\(title.cleaned.slugged)»\(tvdbId)\" playActionID=\"showShow»\(id)»\(title.cleaned.slugged)»\(tvdbId)\">"
        string += "<img class=\"img\" src=\"\(posterImage)\" width=\"250\" height=\"375\" />"
        string += "<title style=\"tv-text-highlight-style: marquee-and-show-on-highlight;\">\(title.cleaned)</title>"
        string += "</lockup>"
        return string
    }

    var lockUpGenre: String {
        let string = "<img class=\"img\" src=\"\(posterImage)\" width=\"250\" height=\"375\" />"
        return string
    }

}
