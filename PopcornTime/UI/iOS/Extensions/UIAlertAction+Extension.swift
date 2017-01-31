

import Foundation

extension UIAlertAction {
    
    private struct AssociatedKeys {
        static var checkedKey = "UIAlertAction.checkedKey"
    }
    
    @nonobjc var isChecked: Bool {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.checkedKey) as? Bool ?? false
        } set (checked) {
            objc_setAssociatedObject(self, &AssociatedKeys.checkedKey, checked, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            
            imageView = imageView ?? UIImageView()
            imageView?.image = checked ? UIImage(named: "Checkmark")?.withRenderingMode(.alwaysTemplate) : nil
        }
    }
    
    @nonobjc var alertController: UIAlertController? {
        get {
            return perform(Selector(("_alertController"))).takeUnretainedValue() as? UIAlertController
        } set(vc) {
            perform(Selector(("_setAlertController:")), with: vc)
        }
    }
    
    private var view: UIView? {
        return alertController?.view.recursiveSubviews.filter({type(of: $0) == NSClassFromString("_UIInterfaceActionCustomViewRepresentationView")}).flatMap({$0.value(forKeyPath: "action.customContentView") as? UIView}).first(where: {$0.value(forKey: "action") as? UIAlertAction == self})
    }
    
    var imageView: UIImageView? {
        get {
            return view?.value(forKey: "_checkView") as? UIImageView
        } set(new) {
            view?.setValue(new, forKey: "_checkView")
            guard let new = new, let view = view else { return }
            view.addSubview(new)
            new.translatesAutoresizingMaskIntoConstraints = false
            
            new.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -15).isActive = true
            new.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        }
    }
}
