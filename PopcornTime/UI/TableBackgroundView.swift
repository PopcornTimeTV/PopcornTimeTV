

import UIKit

class TableBackgroundView: UIView {
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var descriptionLabel: UILabel!
    
    
    func setUpView(image: UIImage, title: String? = nil, description: String? = nil) {
        imageView.image = image
        titleLabel.text = title
        descriptionLabel.text = description
    }
    
    func setUpView(error: NSError) {
        var helpfulDescription = error.localizedDescription
        var title = String()
        switch error.code {
        case -1200:
            title = "SSL Error"
            helpfulDescription = "It looks like your ISP/Network admin is blocking our servers. You can try again with a VPN to hide your internet traffic from them. Please do so your own risk."
        case -404:
            title = "Not found"
            helpfulDescription = "Please check your internet connection and try again."
        case -403:
            title = "Forbidden"
            helpfulDescription = "Sorry, it looks like you're not on the guest list!"
        case -1005, -1009:
            title = "Network connection lost"
            helpfulDescription = "Popcorn Time will automatically reconnect once it detects a valid internet connection."
        default:
            title = "Unknown Error"
            helpfulDescription = "Uh Oh! An unknown error has occured. Please try again."
        }
        setUpView(image: UIImage(named: "Error")!, title: title, description: helpfulDescription)
    }
}
