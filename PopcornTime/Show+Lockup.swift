

import PopcornKit

extension Show {

    var lockUp: String {
        var string = "<lockup actionID=\"showShow»\(id)»\(slug)»\(tvdbId)\" playActionID=\"showShow»\(id)»\(slug)»\(tvdbId)\">"
        string += "<img class=\"img\" src=\"\(mediumCoverImage ?? "")\" width=\"250\" height=\"375\" />"
        string += "<title style=\"tv-text-highlight-style: marquee-and-show-on-highlight;\">\(title.cleaned)</title>"
        string += "</lockup>"
        return string
    }

    var lockUpGenre: String {
        let string = "<img class=\"img\" src=\"\(mediumCoverImage ?? "")\" width=\"250\" height=\"375\" />"
        return string
    }

}
