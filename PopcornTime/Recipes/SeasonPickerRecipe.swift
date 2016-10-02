

import TVMLKitchen
import PopcornKit

public struct Season {
    public var seasonNumber: Int!
    public var seasonId: String!
    public var episodes: [Episode]!
    public var seasonLargeCoverImage: String!
    public var seasonMediumCoverImage: String!
    public var seasonSmallCoverImage: String!

    public init() {

    }
}

public struct SeasonPickerRecipe: RecipeType {

    let show: Show
    let seasons: [Season]
    public let presentationType = PresentationType.Modal

    public init(show: Show, seasons: [Season]) {
        self.show = show
        self.seasons = seasons.sort({ $0.seasonNumber < $1.seasonNumber })
    }

    public var xmlString: String {
        var xml = "<?xml version=\"1.0\" encoding=\"UTF-8\" ?>"
        xml += "<document>"
        xml += template
        xml += "</document>"
        return xml
    }

    var seasonsString: String {
        let mapped: [String] = seasons.map {
            var string = "<lockup actionID=\"showSeason»\(show.id)»\(show.title.slugged)»\(show.tvdbId)»\($0.seasonNumber)\">" + "\n"
            string += "<img src=\"\($0.seasonMediumCoverImage)\" width=\"300\" height=\"452\" />" + "\n"
            string += "<title class=\"white-color\">Season \($0.seasonNumber)</title>" + "\n"
            string += "</lockup>" + "\n"
            return string
        }
        return mapped.joined(separator: "\n")
    }

    public var template: String {
        var xml = ""
        if let file = Bundle.main.url(forResource: "SeasonPickerRecipe", withExtension: "xml") {
            do {
                xml = try String(contentsOf: file)
                xml = xml.stringByReplacingOccurrencesOfString("{{TITLE}}", withString: show.title.cleaned)
                xml = xml.replacingOccurrences(of: "{{SEASONS}}", with: seasonsString)
                xml = xml.stringByReplacingOccurrencesOfString("{{IMAGE}}", withString: show.posterImage)
            } catch {
                print("Could not open Catalog template")
            }
        }
        return xml
    }

}
