

import Foundation

#if os(iOS)
    
    class BaseCollectionViewCell: UICollectionViewCell {
        
        @IBOutlet var highlightView: UIView?
        
        override var isHighlighted: Bool {
            didSet {
                if isHighlighted {
                    highlightView?.isHidden = false
                    highlightView?.alpha = 1.0
                } else {
                    UIView.animate(withDuration: 0.1, delay: 0.0, options: [.curveEaseOut, .allowUserInteraction], animations: { [unowned self] in
                        self.highlightView?.alpha = 0.0
                        }, completion: { _ in
                            self.highlightView?.isHidden = true
                    })
                }
            }
        }
    }
    
#elseif os(tvOS)
    
    typealias BaseCollectionViewCell = UICollectionViewCell

#endif

