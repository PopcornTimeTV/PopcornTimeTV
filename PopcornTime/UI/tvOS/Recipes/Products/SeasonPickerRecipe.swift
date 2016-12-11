

import TVMLKitchen
import PopcornKit

struct SeasonPickerRecipe: RecipeType {

    let show: Show
    let seasonImages: [String?]
    let presentationType = PresentationType.modal

    init(show: Show, seasonImages: [String?]) {
        self.show = show
        self.seasonImages = seasonImages
    }

    var xmlString: String {
        var xml = "<?xml version=\"1.0\" encoding=\"UTF-8\" ?>"
        xml += "<document>"
        xml += template
        xml += "</document>"
        return xml
    }

    var seasonsString: String {
        let mapped: [String] = show.seasonNumbers.map {
            var string = "<lockup actionID=\"showSeason»\($0)\">" + "\n"
            string += "<img src=\"\(seasonImages[show.seasonNumbers.index(of: $0)!] ?? show.largeCoverImage ?? "")\" width=\"300\" height=\"452\" />" + "\n"
            string += "<title class=\"white-color\">Season \($0)</title>" + "\n"
            string += "</lockup>" + "\n"
            return string
        }
        return mapped.joined(separator: "\n")
    }

    var template: String {
        var xml = ""
        if let file = Bundle.main.url(forResource: "SeasonPickerRecipe", withExtension: "xml") {
            do {
                xml = try String(contentsOf: file)
                xml = xml.replacingOccurrences(of: "{{TITLE}}", with: show.title.cleaned)
                xml = xml.replacingOccurrences(of: "{{SEASONS}}", with: seasonsString)
                xml = xml.replacingOccurrences(of: "{{IMAGE}}", with: show.largeBackgroundImage ?? "")
            } catch {
                print("Could not open Catalog template")
            }
        }
        return xml
    }

}
