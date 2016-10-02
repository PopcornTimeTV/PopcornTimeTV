

import PopcornKit

extension Show {

    var carousel: String {
        var string = "<lockup actionID=\"showShow»\(id)»\(title.cleaned.slugged)»\(tvdbId)\" playActionID=\"showShow»\(id)»\(title.cleaned.slugged)»\(tvdbId)\">"
        string += "<img class=\"carousel\" src=\"\(largeCoverImage ?? "")\" width=\"1740\" height=\"500\" />"
        string += "<overlay class=\"overlay\">"
        string += "<title class=\"text\">\(title.cleaned)</title>"
        string += "<subtitle class=\"text\">TV Show</subtitle>"
        string += "</overlay>"
        string += "</lockup>"
        return string
    }

}
