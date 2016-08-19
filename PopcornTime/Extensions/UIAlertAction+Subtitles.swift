//
//  UIAlertAction+Subtitles.swift
//  PopcornTime
import UIKit
private var _encoding : String = ""
extension UIAlertAction {
    var encodingArg : String {
        get {
            return (objc_getAssociatedObject(self, &_encoding) as? String)!
        }
        set(newValue) {
            objc_setAssociatedObject(self, &_encoding, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
        }
    }
    convenience init(title: String?, style:UIAlertActionStyle, encoding:String?, handler: ((UIAlertAction) -> Void)?){
        self.init(title:title, style:style, handler:handler)
        encodingArg=encoding!
    }
}
