

import TVMLKitchen
import PopcornKit

public struct DescriptionRecipe: RecipeType {
    
    public let theme = DefaultTheme()
    public let presentationType: PresentationType
    public let title: String
    public let description: String
    public let buttons: [(title: String, actionID: String)]
    
    public init(title: String, message: String,
                buttons: [(title: String, actionID: String)] = [(title: "Dismiss", actionID: "closeAlert")],
                presentationType: PresentationType = .modal) {
        self.title = title
        self.description = message
        self.buttons = buttons
        self.presentationType = presentationType
    }

    public var xmlString: String {
        var xml = "<?xml version=\"1.0\" encoding=\"UTF-8\" ?>"
        xml += "<document>"
        xml += template
        xml += "</document>"
        return xml
    }
    
    fileprivate var buttonString: String {
        let mapped: [String] = buttons.map {
            var string = "<button actionID=\"\($0.actionID)\">"
            string += "<text>\($0.title)</text>"
            string += "</button>"
            return string
        }
        return mapped.joined(separator: "")
    }

    public var template: String {
        var xml = ""
        if let file = Bundle.main.url(forResource: "DescriptionRecipe", withExtension: "xml") {
            do {
                xml = try String(contentsOf: file)
                xml = xml.replacingOccurrences(of: "{{TITLE}}", with: title.cleaned)
                xml = xml.replacingOccurrences(of: "{{DESCRIPTION}}", with: description.cleaned)
                xml = xml.replacingOccurrences(of: "{{BUTTONS}}", with: buttonString)
            } catch {
                print("Could not open Catalog template")
            }
        }
        return xml
    }

}
