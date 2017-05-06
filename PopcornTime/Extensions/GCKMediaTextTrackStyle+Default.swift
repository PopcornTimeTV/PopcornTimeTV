

import Foundation
import GoogleCast.GCKMediaTextTrackStyle

extension GCKMediaTextTrackStyle {
    
    static var `default`: GCKMediaTextTrackStyle {
        let `self` = GCKMediaTextTrackStyle()
        
        let settings = SubtitleSettings.shared
        
        self.foregroundColor = GCKColor(uiColor: settings.color)
        self.edgeType = .dropShadow
        self.fontFamily = settings.font.familyName
        
        switch settings.style {
        case .bold:
            self.fontStyle = .bold
        case .boldItalic:
            self.fontStyle = .boldItalic
        case .italic:
            self.fontStyle = .italic
        case .normal:
            self.fontStyle = .normal
        }
        
        return self
    }
}
