

import TVMLKitchen
import PopcornKit

public struct WelcomeRecipe: RecipeType {
    public let theme = DefaultTheme()
    public let presentationType = PresentationType.defaultWithLoadingIndicator
    
    let title: String
    
    
    init(title: String) {
        self.title = title
        PopcornKit.loadMovies { (movies, error) in
            guard let movies = movies else { return }
            let art = movies.flatMap({$0.largeBackgroundImage}).filter({!$0.isAmazonUrl})
            Kitchen.appController.evaluate(inJavaScriptContext: { (context) in
                context.objectForKeyedSubscript("changeImage").call(withArguments: [art[Int(arc4random_uniform(UInt32(art.count)))]])
            }, completion: nil)
        }
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
        if let file = Bundle.main.url(forResource: "WelcomeRecipe", withExtension: "xml") {
            do {
                xml = try String(contentsOf: file)
            } catch {
                print("Could not open Catalog template")
            }
        }
        return xml
    }
    
}
