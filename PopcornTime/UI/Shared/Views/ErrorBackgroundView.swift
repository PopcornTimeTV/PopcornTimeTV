

import UIKit

class ErrorBackgroundView: UIView {
    @IBOutlet var titleLabel: UILabel?
    @IBOutlet var descriptionLabel: UILabel?
    
    
    func setUpView(title: String? = nil, description: String? = nil) {
        titleLabel?.text = title
        descriptionLabel?.text = description
    }
    
    func setUpView(error: NSError) {
        let helpfulDescription: String
        let title: String
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
            title = "You're Offline"
            helpfulDescription = "Please make sure you have a valid internet connection and try again."
        default:
            title = "Unknown Error"
            helpfulDescription = "Uh Oh! An unknown error has occured (\(error.localizedDescription)). Please try again."
        }
        setUpView(title: title, description: helpfulDescription)
    }
}
