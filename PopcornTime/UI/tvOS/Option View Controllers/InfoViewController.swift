

import UIKit
import PopcornKit
import AlamofireImage

class InfoViewController: UIViewController, UIViewControllerTransitioningDelegate {
    
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var infoLabel: UILabel!
    @IBOutlet var summaryTextView: TVExpandableTextView!
    
    @IBOutlet var contentView: UIView!
    @IBOutlet var noInfoLabel: UILabel!
    
    let topGuide = UIFocusGuide()
    
    var tabBar: UITabBar! {
        return (parent as? OptionsViewController)?.tabBar
    }
    
    var environmentsToFocus: [UIFocusEnvironment] {
        get {
            return (parent as? OptionsViewController)?.environmentsToFocus ?? []
        } set(environments) {
            (parent as? OptionsViewController)?.environmentsToFocus = environments
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        topGuide.preferredFocusEnvironments = [summaryTextView]
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        parent?.view.layoutGuides.forEach({
            $0.isKind(of: UIFocusGuide.self) ? $0.owningView?.removeLayoutGuide($0) : ()
        })
        parent?.view.addLayoutGuide(topGuide)
        
        topGuide.topAnchor.constraint(equalTo: tabBar.bottomAnchor).isActive = true
        topGuide.leftAnchor.constraint(equalTo: parent!.view.leftAnchor).isActive = true
        topGuide.rightAnchor.constraint(equalTo: parent!.view.rightAnchor).isActive = true
        topGuide.bottomAnchor.constraint(equalTo: summaryTextView.topAnchor).isActive = true
    }
    
    
    var media: Media? {
        didSet {
            guard let media = media else {
                contentView.isHidden = true
                noInfoLabel.isHidden = false
                return
            }
            
            titleLabel.text = media.title
            summaryTextView.textColor = UIColor(white: 1.0, alpha: 0.5)
            summaryTextView.text = media.summary
            summaryTextView.blurStyle = .light
            summaryTextView.blurredView.contentView.backgroundColor = nil
            summaryTextView.buttonWasPressed = moreButtonWasPressed
            
            let formatter = DateComponentsFormatter()
            formatter.unitsStyle = .short
            formatter.allowedUnits = [.hour, .minute]
            
            if let movie = media as? Movie {
                if let imageString = movie.smallCoverImage,
                    let imageUrl = URL(string: imageString) {
                    imageView.af_setImage(withURL: imageUrl)
                }
                
                let runtime = formatter.string(from: TimeInterval(movie.runtime) * 60)
                let year = movie.year
                
                let info = NSMutableAttributedString(string: [runtime, "\(year)"].compactMap({$0}).joined(separator: "\t"))
                attributedString(between: movie.certification, "HD", "CC").forEach({info.append($0)})
                
                infoLabel.attributedText = info
            } else if let episode = media as? Episode {
                if let imageString = episode.show?.smallCoverImage,
                    let imageUrl = URL(string: imageString) {
                    imageView.af_setImage(withURL: imageUrl)
                }
                
                let season = "S\(episode.season):E\(episode.episode)"
                let date = DateFormatter.localizedString(from: episode.firstAirDate, dateStyle: .medium, timeStyle: .none)
                let runtime = formatter.string(from: TimeInterval(episode.show?.runtime ?? 0) * 60)
                let genre = episode.show?.genres.first?.localizedCapitalized.localized
                
                
                let info = NSMutableAttributedString(string: [season, date, runtime, genre].compactMap({$0}).joined(separator: "\t"))
                attributedString(between: "HD", "CC").forEach({info.append($0)})
                
                infoLabel.attributedText = info
            }
        }
    }
    
    func moreButtonWasPressed(text: String?) {
        let viewController = UIStoryboard.main.instantiateViewController(withIdentifier: "TVDescriptionViewController") as! TVDescriptionViewController
        viewController.loadView()
        viewController.titleLabel.text = nil
        viewController.textView.text = text
        viewController.transitioningDelegate = self
        viewController.modalPresentationStyle = .custom
        environmentsToFocus = [summaryTextView]
        present(viewController, animated: true)
    }
    
    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        super.didUpdateFocus(in: context, with: coordinator)
        
        summaryTextView.textColor = summaryTextView.isFocused ? .white : UIColor(white: 1.0, alpha: 0.5)
    }
    
    // MARK: - Presentation
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        if presented is TVDescriptionViewController {
            return TVBlurOverCurrentContextAnimatedTransitioning(isPresenting: true)
        }
        return nil
        
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        if dismissed is TVDescriptionViewController {
            return TVBlurOverCurrentContextAnimatedTransitioning(isPresenting: false)
        }
        return nil
    }
}
