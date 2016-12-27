
import Foundation
import JavaScriptCore


@objc protocol SearchRecipeJSExports: JSExport {
    
    func segmentBarDidChangeSegment(_ rawValue: String)
    
    var doc: JSValue? { get set }
}
