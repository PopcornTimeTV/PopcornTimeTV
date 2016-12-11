

import TVMLKitchen
import PopcornKit

class CatalogRecipe: RecipeType {
    
    let theme = DefaultTheme()
    var presentationType = PresentationType.defaultWithLoadingIndicator

    let title: String
    var currentPage = 0
    var isLoading: Bool = false
    let fetchBlock: (Int, @escaping (String) -> Void) -> Void

    init(title: String, fetchBlock: @escaping (Int, @escaping (String) -> Void) -> Void) {
        self.title = title
        self.fetchBlock = fetchBlock
        lockup() { (lockUp) in
            self.lockUpString = lockUp
        }
    }

    open var xmlString: String {
        var xml = "<?xml version=\"1.0\" encoding=\"UTF-8\" ?>"
        xml += "<document>"
        xml += template
        xml += "</document>"
        return xml
    }

    var lockUpString: String = ""

    open var template: String {
        var xml = ""
        if let file = Bundle.main.url(forResource: "CatalogRecipe", withExtension: "xml") {
            do {
                xml = try String(contentsOf: file)
                xml = xml.replacingOccurrences(of: "{{TITLE}}", with: title)
                xml = xml.replacingOccurrences(of: "{{POSTERS}}", with: lockUpString)
            } catch {
                print("Could not open Catalog template")
            }
        }
        return xml
    }

    open func lockup(didChangePage completion: @escaping (String) -> Void) {
        guard !isLoading else { return }
        isLoading = true
        currentPage += 1
        fetchBlock(currentPage, {
            self.isLoading = false
            completion($0)
        })
    }
}
