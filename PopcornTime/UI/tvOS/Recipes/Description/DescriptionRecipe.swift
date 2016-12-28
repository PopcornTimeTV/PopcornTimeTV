

import TVMLKitchen
import PopcornKit

public struct DescriptionRecipe: RecipeType {
    
    public let theme = DefaultTheme()
    public let presentationType: PresentationType
    public let title: String
    public let description: String
    
    public init(title: String, message: String, presentationType: PresentationType = .modal) {
        self.title = title
        self.description = message
        self.presentationType = presentationType
    }

    public var xmlString: String {
        var xml = "<?xml version=\"1.0\" encoding=\"UTF-8\" ?>"
        xml += "<document>"
        xml += template
        xml += "</document>"
        return xml
    }

    public var template: String {
        let file = Bundle.main.url(forResource: "DescriptionRecipe", withExtension: "xml")!
        var xml = try! String(contentsOf: file)
        xml = xml.replacingOccurrences(of: "{{TITLE}}", with: title.cleaned)
        xml = xml.replacingOccurrences(of: "{{DESCRIPTION}}", with: description.cleaned)
        return xml
    }

}
