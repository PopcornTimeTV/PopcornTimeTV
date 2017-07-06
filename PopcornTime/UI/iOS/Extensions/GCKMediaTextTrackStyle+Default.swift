

import Foundation
import GoogleCast.GCKMediaTextTrackStyle

extension GCKMediaTextTrackStyle {
    
    static var `default`: GCKMediaTextTrackStyle {
        let `self` = GCKMediaTextTrackStyle()
        
        let settings = SubtitleSettings.shared
        
        self.foregroundColor = GCKColor(uiColor: settings.color)
        self.edgeType = .dropShadow
        self.fontFamily = settings.font.familyName
        self.windowType = .none
        
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
        
        switch settings.size {
        case .small:
            self.fontScale = 0.5
        case .medium:
            self.fontScale = 1.0
        case .mediumLarge:
            self.fontScale = 1.5
        case .large:
            self.fontScale = 2.0
        }
        
        return self
    }
}
