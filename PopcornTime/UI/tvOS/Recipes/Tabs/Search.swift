

import TVMLKitchen
import PopcornKit

class Search: TabItem {

    let title = "Search"
    var recipe: SearchRecipe?

    func handler() {
        recipe = recipe ?? {
            let recipe = SearchRecipe()
            Kitchen.appController.evaluate(inJavaScriptContext: { (context) in
                
                let filterSearchTextBlock: @convention(block) (String, JSValue) -> () =  { (text, callback) in
                    recipe.filterSearchText(text) { string in
                        if callback.isObject {
                            callback.call(withArguments: [string])
                        }
                    }
                }
                
                let segmentBarDidChangeSegment: @convention(block) (String) -> () =  { (rawValue) in
                    recipe.fetchType = Trakt.MediaType(rawValue: rawValue)!
                }
                
                context.setObject(unsafeBitCast(segmentBarDidChangeSegment, to: AnyObject.self),
                                  forKeyedSubscript: "segmentBarDidChangeSegment" as (NSCopying & NSObjectProtocol)!)
                
                context.setObject(unsafeBitCast(filterSearchTextBlock, to: AnyObject.self),
                                  forKeyedSubscript: "filterSearchText" as (NSCopying & NSObjectProtocol)!)
                
                let file = Bundle.main.url(forResource: "SearchRecipe", withExtension: "js")!
                let js = try! String(contentsOf: file).replacingOccurrences(of: "{{RECIPE}}", with: recipe.xmlString)
                context.evaluateScript(js)
                
            }, completion: nil)
            return recipe
        }()
    }

}
