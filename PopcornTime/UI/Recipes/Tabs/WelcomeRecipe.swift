

import TVMLKitchen
import PopcornKit

public struct WelcomeRecipe: RecipeType {
    public let theme = DefaultTheme()
    public let presentationType = PresentationType.defaultWithLoadingIndicator
    
    let title: String
    var randomArt: [String]
    
    
    init(title: String, randomArt: [String]) {
        self.title = title
        self.randomArt = randomArt
    }
    
    public var xmlString: String {
        var xml = "<?xml version=\"1.0\" encoding=\"UTF-8\" ?>"
        xml += "<document>"
        xml += template
        xml += "</document>"
        return xml
    }
    
    public var randomBackgroundImage: String? {
        return randomArt[Int(arc4random_uniform(UInt32(randomArt.count)))]
    }
    
    func buildShelf(_ title: String, content: String) -> String {
        var shelf = "<shelf><header><title>"
        shelf += title
        shelf += "</title></header><section>"
        shelf += content
        shelf += "</section></shelf>"
        return shelf
    }
    
    public var template: String {
        var xml = ""
        if let file = Bundle.main.url(forResource: "WelcomeRecipe", withExtension: "xml") {
            do {
                xml = try String(contentsOf: file)
                xml = xml.replacingOccurrences(of: "{{TVSHOWS_BACKGROUND}}", with: randomBackgroundImage ?? "")
            } catch {
                print("Could not open Catalog template")
            }
        }
        return xml
    }
    
}
