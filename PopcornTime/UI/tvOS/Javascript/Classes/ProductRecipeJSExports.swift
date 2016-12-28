
import Foundation
import JavaScriptCore


@objc protocol ProductRecipeJSExports: JSExport {
    
    var doc: JSValue? { get set }
    
    func disableThemeSong()
    func enableThemeSong()
    
    func updateWatchlistButton()
    func updateWatchedButton()
    
    var watchlistStatusButtonImage: String { get }
    var watchedStatusButtonImage: String { get }
}
