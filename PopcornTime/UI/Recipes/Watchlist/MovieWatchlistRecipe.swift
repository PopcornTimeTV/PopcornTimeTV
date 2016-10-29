

import TVMLKitchen
import PopcornKit

public struct MovieWatchlistRecipe: RecipeType {

    public let theme = DefaultTheme()
    public let presentationType = PresentationType.tab

    let title: String
    var items: [Movie]

    init(title: String, movies: [Movie]) {
        self.title = title
        self.items = movies
    }

    public var xmlString: String {
        var xml = "<?xml version=\"1.0\" encoding=\"UTF-8\" ?>"
        xml += "<document>"
        xml += template
        xml += "</document>"
        return xml
    }

    public var movieString: String {
        let mapped: [String] = items.map {
            var string = "<lockup actionID=\"showMovie»\($0.title.cleaned)»\($0.id)\">"
            string += "<img src=\"\($0.mediumCoverImage ?? "")\" width=\"250\" height=\"375\" />"
            string += "<title class=\"hover\">\($0.title.cleaned)</title>"
            string += "</lockup>"
            return string
        }
        return mapped.joined(separator: "")
    }

    public var template: String {
        var xml = ""
        if let file = Bundle.main.url(forResource: "CatalogRecipe", withExtension: "xml") {
            do {
                xml = try String(contentsOf: file)
                xml = xml.replacingOccurrences(of: "{{TITLE}}", with: title)
                xml = xml.replacingOccurrences(of: "{{POSTERS}}", with: movieString)
            } catch {
                print("Could not open Catalog template")
            }
        }
        return xml
    }

}
