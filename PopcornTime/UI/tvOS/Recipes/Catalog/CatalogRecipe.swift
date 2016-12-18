

import TVMLKitchen
import PopcornKit

class CatalogRecipe: RecipeType {
    
    let theme = DefaultTheme()
    var presentationType = PresentationType.defaultWithLoadingIndicator

    let title: String
    var currentPage = 0
    var isLoading: Bool = false
    var hasNextPage: Bool = false
    let fetchBlock: (Int, @escaping (CatalogRecipe, String?, NSError?, Bool) -> Void) -> Void

    init(title: String, fetchBlock: @escaping (Int, @escaping (CatalogRecipe, String?, NSError?, Bool) -> Void) -> Void) {
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
        hasNextPage = false
        currentPage += 1
        fetchBlock(currentPage, { (recipe, media, error, hidden) in
            self.isLoading = false
            
            guard let media = media else {
                guard let error = error else { return }
                let backgroundView = ErrorBackgroundView()
                backgroundView.setUpView(error: error)
                Kitchen.serve(xmlString: backgroundView.xmlString, type: .tab)
                return
            }
            
            if self.currentPage == 1 { ActionHandler.shared.serveCatalogRecipe(recipe, topBarHidden: hidden) } // Only present the recipe if it's the first page.
            
            if !media.isEmpty {
                self.hasNextPage = true
            }
            
            completion(media)
        })
    }
}
