

import UIKit

@IBDesignable class TVVisualEffectView: UIVisualEffectView {
    
    @IBInspectable var blurRadius: CGFloat {
        get {
            return effect?.value(forKey: "blurRadius") as? CGFloat ?? 90
        } set (radius) {
            effect?.setValue(radius, forKey: "blurRadius")
        }
    }
    
    override init(effect: UIVisualEffect?) {
        guard let effect = effect as? UIBlurEffect else {
            fatalError("Effect must be of class: UIBlurEffect")
        }
        super.init(effect: effect)
        
        let new = sharedSetup(effect: effect)
        
        self.effect = new
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        guard let effect = effect as? UIBlurEffect else {
            fatalError("Effect must be of class: UIBlurEffect")
        }
        
        let new = sharedSetup(effect: effect)
        
        self.effect = new
    }
    
    private func sharedSetup(effect: UIBlurEffect, radius: CGFloat = 90) -> UIBlurEffect {
        let UICustomBlurEffect = NSClassFromString("_UICustomBlurEffect") as! UIBlurEffect.Type
        let raw = effect.value(forKey: "_style") as! Int
        let style = UIBlurEffectStyle(rawValue: raw)!

        let effect = UICustomBlurEffect.init(style: style)
        effect.setValue(1.0, forKey: "scale")
        effect.setValue(radius, forKey: "blurRadius")
        effect.setValue(UIColor.clear, forKey: "colorTint")
        
        return effect
    }
}
