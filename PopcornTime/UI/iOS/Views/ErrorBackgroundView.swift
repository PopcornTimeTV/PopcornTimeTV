

import UIKit

class ErrorBackgroundView: UIView {
    @IBOutlet var imageView: UIImageView?
    @IBOutlet var titleLabel: UILabel?
    @IBOutlet var descriptionLabel: UILabel?
    
    var title: String? {
        didSet {
            titleLabel?.text = title
        }
    }
    var errorDescription: String? {
        didSet {
            descriptionLabel?.text = errorDescription
        }
    }
    var image: UIImage? {
        didSet {
            imageView?.image = image
        }
    }
    
    
    func setUpView(image: UIImage? = nil, title: String? = nil, description: String? = nil) {
        self.image = image
        self.title = title
        self.errorDescription = description
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
            title = "You're Offline"
            helpfulDescription = "Please make sure you have a valid internet connection and try again."
        default:
            title = "Unknown Error"
            helpfulDescription = "Uh Oh! An unknown error has occured. Please try again."
        }
        setUpView(image: UIImage(named: "Error"), title: title, description: helpfulDescription)
    }
    
    var xmlString: String {
        var xml = "<?xml version=\"1.0\" encoding=\"UTF-8\" ?>"
        xml += "<document>"
        xml += template
        xml += "</document>"
        return xml
    }
    
    var template: String {
        var xml = ""
        if let file = Bundle.main.url(forResource: "ErrorRecipe", withExtension: "xml") {
            do {
                xml = try String(contentsOf: file)
                xml = xml.replacingOccurrences(of: "{{TITLE}}", with: title ?? "")
                xml = xml.replacingOccurrences(of: "{{DESCRIPTION}}", with: errorDescription ?? "")
            } catch {
                print("Could not open Catalog template")
            }
        }
        return xml
    }
}
