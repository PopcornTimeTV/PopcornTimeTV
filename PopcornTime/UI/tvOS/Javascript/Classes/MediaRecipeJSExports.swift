
import Foundation
import JavaScriptCore


@objc protocol MediaRecipeJSExports: JSExport {
    
    func loadNextPage(_ completion: JSValue)
    func toggleWatched(_ actionID: String)
    
    var isLoading: Bool { get set }
    
    var hasNextPage: Bool { get set }
    
    var doc: JSValue? { get set }
}
