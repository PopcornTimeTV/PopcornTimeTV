

import Foundation
import MobileCoreServices

extension URL {
    
    /// Returns the **MIME** type of the current file. If an error occurs, `"application/octet-stream"` is returned.
    var contentType: String {
        let defaultMime = "application/octet-stream"
        
        guard !pathExtension.isEmpty else {
            return defaultMime
        }
        
        
        let uti: CFString? = {
            let utiRef = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, pathExtension as CFString, nil)
            let uti = utiRef?.takeUnretainedValue()
            utiRef?.release()
            return uti
        }()
        
        let mime: String? = {
            guard let uti = uti else { return nil }

            let mimeRef = UTTypeCopyPreferredTagWithClass(uti, kUTTagClassMIMEType)
            let mime = mimeRef?.takeUnretainedValue()
            mimeRef?.release()
            
            return mime as String?
        }()
        
        return mime ?? defaultMime
    }
}
