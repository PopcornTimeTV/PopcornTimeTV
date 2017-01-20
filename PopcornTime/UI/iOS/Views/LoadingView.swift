

import Foundation

enum LoadingViewStyle {
    case dark
    case light
}

class LoadingView: UIView {
    @IBOutlet var activityIndicatorView: UIActivityIndicatorView!
    @IBOutlet var loadingLabel: UILabel!
    
    var style: LoadingViewStyle = .light {
        didSet {
            let color: UIColor = style == .dark ? .black : .white
            loadingLabel.textColor = color
            activityIndicatorView.color = color
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}
