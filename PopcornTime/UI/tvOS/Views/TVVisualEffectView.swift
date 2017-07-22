

import UIKit

@IBDesignable class TVVisualEffectView: UIVisualEffectView {
    
    @IBInspectable var blurRadius: CGFloat {
        get {
            return blurEffect.value(forKey: "blurRadius") as? CGFloat ?? 90
        } set (radius) {
            blurEffect.setValue(radius, forKey: "blurRadius")
            effect = blurEffect
        }
    }
    
    private var blurEffect: UIBlurEffect!
    
    override init(effect: UIVisualEffect?) {
        guard let effect = effect as? UIBlurEffect else {
            fatalError("Effect must be of class: UIBlurEffect")
        }
        super.init(effect: effect)
        
        sharedSetup(effect: effect)
        
        self.effect = blurEffect
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        guard let effect = effect as? UIBlurEffect else {
            fatalError("Effect must be of class: UIBlurEffect")
        }
        
        sharedSetup(effect: effect)
        
        self.effect = blurEffect
    }
    
    private func sharedSetup(effect: UIBlurEffect, radius: CGFloat = 90) {
        let UICustomBlurEffect = NSClassFromString("_UICustomBlurEffect") as! UIBlurEffect.Type
        let raw = effect.value(forKey: "_style") as! Int
        let style = UIBlurEffectStyle(rawValue: raw)!

        let effect = UICustomBlurEffect.init(style: style)
        effect.setValue(1.0, forKey: "scale")
        effect.setValue(radius, forKey: "blurRadius")
        effect.setValue(UIColor.clear, forKey: "colorTint")
        
        self.blurEffect = effect
    }
}
