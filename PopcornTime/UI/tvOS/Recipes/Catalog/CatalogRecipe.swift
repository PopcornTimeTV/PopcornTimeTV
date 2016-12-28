

import TVMLKitchen
import PopcornKit

class CatalogRecipe: RecipeType {
    
    let theme = DefaultTheme()
    var presentationType = PresentationType.default

    let title: String
    let lockup: String

    init(title: String, media: String) {
        self.title = title
        lockup = media
    }

    open var xmlString: String {
        var xml = "<?xml version=\"1.0\" encoding=\"UTF-8\" ?>"
        xml += "<document>"
        xml += template
        xml += "</document>"
        return xml
    }

    open var template: String {
        let file = Bundle.main.url(forResource: "CatalogRecipe", withExtension: "xml")!
        var xml = try! String(contentsOf: file)
        xml = xml.replacingOccurrences(of: "{{TITLE}}", with: title)
        xml = xml.replacingOccurrences(of: "{{LOCKUPS}}", with: lockup)
        return xml
    }
}
