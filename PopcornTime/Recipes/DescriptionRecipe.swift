

import TVMLKitchen
import PopcornKit

public struct DescriptionRecipe: RecipeType {

    let title: String
    let description: String

    public let theme = DefaultTheme()
    public let presentationType = PresentationType.Modal

    public init(title: String, description: String) {
        self.title = title
        self.description = description
    }

    public var xmlString: String {
        var xml = "<?xml version=\"1.0\" encoding=\"UTF-8\" ?>"
        xml += "<document>"
        xml += template
        xml += "</document>"
        return xml
    }

    public var template: String {
        var xml = ""
        if let file = NSBundle.mainBundle().URLForResource("DescriptionRecipe", withExtension: "xml") {
            do {
                xml = try String(contentsOfURL: file)
                xml = xml.stringByReplacingOccurrencesOfString("{{TITLE}}", withString: title.cleaned)
                xml = xml.stringByReplacingOccurrencesOfString("{{DESCRIPTION}}", withString: description.cleaned)
            } catch {
                print("Could not open Catalog template")
            }
        }
        return xml
    }

}
