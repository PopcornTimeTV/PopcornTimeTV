

import TVMLKitchen
import PopcornKit

public struct DescriptionButton {
    
    let title: String
    let actionID: String?
    
    public init(title: String, actionID: String? = nil) {
        self.title = title
        self.actionID = actionID
    }
    
}

public struct DescriptionRecipe: RecipeType {
    
    public let theme = DefaultTheme()
    public let presentationType: PresentationType
    public let title: String
    public let description: String
    public let buttons: [DescriptionButton]
    
    public init(title: String, message: String,
                buttons: [DescriptionButton] = [],
                presentationType: PresentationType = .Modal) {
        self.title = title
        self.description = message
        self.buttons = buttons
        self.presentationType = presentationType
    }

    public init(title: String, description: String) {
        self.title = title
        self.description = description
        self.presentationType = PresentationType.Modal
        self.buttons = []
    }

    public var xmlString: String {
        var xml = "<?xml version=\"1.0\" encoding=\"UTF-8\" ?>"
        xml += "<document>"
        xml += template
        xml += "</document>"
        return xml
    }
    
    private var buttonString: String {
        let mapped: [String] = buttons.map {
            var string = ($0.actionID != nil) ? "<button actionID=\"\($0.actionID!)\">" : "<button>"
            string += "<text>\($0.title)</text>"
            string += "</button>"
            return string
        }
        return mapped.joinWithSeparator("")
    }

    public var template: String {
        var xml = ""
        if let file = NSBundle.mainBundle().URLForResource("DescriptionRecipe", withExtension: "xml") {
            do {
                xml = try String(contentsOfURL: file)
                xml = xml.stringByReplacingOccurrencesOfString("{{TITLE}}", withString: title.cleaned)
                xml = xml.stringByReplacingOccurrencesOfString("{{DESCRIPTION}}", withString: description.cleaned)
                xml = xml.stringByReplacingOccurrencesOfString("{{BUTTONS}}", withString: buttonString)
            } catch {
                print("Could not open Catalog template")
            }
        }
        return xml
    }

}
