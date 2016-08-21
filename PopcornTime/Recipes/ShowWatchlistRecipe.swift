

import TVMLKitchen
import PopcornKit

public struct ShowWatchlistRecipe: RecipeType {

    public let theme = DefaultTheme()
    public let presentationType = PresentationType.Tab

    let title: String
    let items: [WatchItem]

    init(title: String, movies: [WatchItem]) {
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
            
            var string = "<lockup actionID=\"showShow»\($0.id)»\($0.slugged)»\($0.tvdbId)\">"
            string += "<img src=\"\($0.coverImage)\" width=\"250\" height=\"375\" />"
            string += "<title class=\"hover\">\($0.name.cleaned)</title>"
            string += "</lockup>"
            return string
        }
        return mapped.joinWithSeparator("")
    }

    public var template: String {
        var xml = ""
        if let file = NSBundle.mainBundle().URLForResource("CatalogRecipe", withExtension: "xml") {
            do {
                xml = try String(contentsOfURL: file)
                xml = xml.stringByReplacingOccurrencesOfString("{{TITLE}}", withString: title)
                xml = xml.stringByReplacingOccurrencesOfString("{{POSTERS}}", withString: movieString)
            } catch {
                print("Could not open Catalog template")
            }
        }
        return xml
    }

}
