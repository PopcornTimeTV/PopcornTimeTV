

import Foundation
import JavaScriptCore
import PopcornKit

@objc class ProductRecipe: NSObject, ProductRecipeJSExports {
    
    dynamic var doc: JSValue?
    dynamic var watchlistStatusButtonImage: String { fatalError("Must be overridden") }
    dynamic var watchedStatusButtonImage: String { fatalError("Must be overridden") }
    
    
    var media: Media { fatalError("Must be overridden") }
    
    func disableThemeSong() {
        ThemeSongManager.shared.stopTheme()
    }
    
    func enableThemeSong() {
        ActionHandler.shared.productRecipe = self
    }
    
    func updateWatchlistButton() {
        guard let watchlistButton = doc?.invokeMethod("getElementById", withArguments: ["watchlistButton"]),
            !watchlistButton.isUndefined else { return }
        
        let src = "resource://" + watchlistStatusButtonImage
        
        watchlistButton.objectForKeyedSubscript("firstChild").invokeMethod("setAttribute", withArguments: ["src", src])
    }
    
    func updateWatchedButton() {
        guard let watchedButton = doc?.invokeMethod("getElementById", withArguments: ["watchedButton"]),
            !watchedButton.isUndefined else { return }
        
        let src = "resource://" + watchedStatusButtonImage
        
        watchedButton.objectForKeyedSubscript("firstChild").invokeMethod("setAttribute", withArguments: ["src", src])
    }
}
