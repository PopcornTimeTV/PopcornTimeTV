

import Foundation

/**
 Protocol wrapper for private subtitle appearance API in MobileVLCKit. Can be toll free bridged from VLCMediaPlayer. Example for changing font:
 
 let mediaPlayer = VLCMediaPlayer()
 (mediaPlayer as VLCFontAppearance).setTextRendererFont!("HelveticaNueve")
 */
@objc protocol VLCFontAppearance {
    /**
     Change color of subtitle font.
     
     [All colors available here](http://www.nameacolor.com/Color%20numbers.htm)
     
     - Parameter fontColor: An `NSNumber` wrapped hexInt (`UInt32`) indicating the color. Eg. Black: 0, White: 16777215, etc.
     */
    @objc optional func setTextRendererFontColor(_ fontColor: NSNumber)
    /**
     Toggle bold on subtitle font.
     
     - Parameter fontForceBold: `NSNumber` wrapped `Bool`.
     */
    @objc optional func setTextRendererFontForceBold(_ fontForceBold: NSNumber)
    /**
     Change the subtitle font.
     
     - Parameter fontname: `NSString` representation of font name. Eg `UIFonts` familyName property.
     */
    @objc optional func setTextRendererFont(_ fontname: NSString)
    /**
     Change the subtitle font size.
     
     - Parameter fontname: `NSNumber` wrapped `Int` of the fonts size.
     
     - Important: Provide the font in reverse size as `libvlc` sets the text matrix to the identity matrix which reverses the font size. Ie. 5pt is really big and 100pt is really small.
     */
    @objc optional func setTextRendererFontSize(_ fontSize: NSNumber)
}

extension VLCMediaPlayer: VLCFontAppearance {}
