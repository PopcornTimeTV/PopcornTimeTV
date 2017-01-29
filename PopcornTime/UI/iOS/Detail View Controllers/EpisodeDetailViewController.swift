

import UIKit
import AlamofireImage
import PopcornKit

class EpisodeDetailViewController: UIViewController, UIScrollViewDelegate, UIGestureRecognizerDelegate {
    
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var subtitleLabel: UILabel!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var infoLabel: UILabel!
    @IBOutlet var summaryTextView: ExpandableTextView!
    @IBOutlet var scrollView: UIScrollView!
    
    var episode: Episode!
    var dismissRecognizer: UITapGestureRecognizer!
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        
        
        view.window?.addGestureRecognizer(dismissRecognizer)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        view.window?.removeGestureRecognizer(dismissRecognizer)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        subtitleLabel.text = "SEASON \(episode.season) • EPISODE \(episode.episode)"
        titleLabel.text = episode.title
        summaryTextView.text = episode.summary
        
        let info = NSMutableAttributedString(string: "\(DateFormatter.localizedString(from: episode.firstAirDate, dateStyle: .medium, timeStyle: .none))    \(episode.show.runtime ?? "0") min\t")
        attributedString(from: "HD", "CC").forEach({info.append($0)})
        infoLabel.attributedText = info
        
        
        if let image = episode.largeBackgroundImage,
            let url = URL(string: image) {
            imageView.af_setImage(withURL: url, placeholderImage: UIImage(named: "Episode Placeholder"), imageTransition: .crossDissolve(animationLength))
        }
        
        dismissRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleDismissTap(_:)))
        dismissRecognizer.numberOfTapsRequired = 1
        dismissRecognizer.cancelsTouchesInView = false
        dismissRecognizer.delegate = self
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    func handleDismissTap(_ sender: UITapGestureRecognizer) {
        guard sender.state == .ended, let rootView = view.window?.rootViewController?.view else { return }
        
        
        let location = sender.location(in: rootView)
        let point = view.convert(location, from: rootView)
        let inView = view.point(inside: point, with: nil)
        
        if !inView {
            dismiss(animated: true, completion: nil)
        }
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
