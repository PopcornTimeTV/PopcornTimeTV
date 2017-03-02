

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
    var interactor: EpisodeDetailPercentDrivenInteractiveTransition?
    
    @IBOutlet var dismissPanGestureRecognizer: UIPanGestureRecognizer!
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        preferredContentSize = scrollView.contentSize
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        subtitleLabel.text = "SEASON \(episode.season) • EPISODE \(episode.episode)"
        titleLabel.text = episode.title
        summaryTextView.text = episode.summary
        
        let info = NSMutableAttributedString(string: "\(DateFormatter.localizedString(from: episode.firstAirDate, dateStyle: .medium, timeStyle: .none))\t\(episode.show.formattedRuntime ?? "0 min")\t")
        attributedString(with: 10, between: "HD", "CC").forEach({info.append($0)})
        infoLabel.attributedText = info
        
        
        if let image = episode.largeBackgroundImage,
            let url = URL(string: image) {
            imageView.af_setImage(withURL: url, placeholderImage: UIImage(named: "Episode Placeholder"), imageTransition: .crossDissolve(animationLength))
        }
        
        scrollView.setNeedsLayout()
        scrollView.layoutIfNeeded()
        preferredContentSize = scrollView.contentSize
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    @IBAction func play(_ sender: UIButton) {
        guard let parent = (transitioningDelegate as? EpisodesCollectionViewController)?.parent as? ShowDetailViewController else { return }
        
        parent.chooseQuality(sender, media: episode)
    }
    
    
    @IBAction func handleDismissPan(_ sender: UIPanGestureRecognizer) {
        let percentThreshold: CGFloat = 0.12
        let superview = sender.view!.superview!
        let translation = sender.translation(in: superview)
        let progress = translation.y/superview.bounds.height/3.0
        
        guard let interactor = interactor else { return }
        
        switch sender.state {
        case .began:
            interactor.hasStarted = true
            dismiss(animated: true, completion: nil)
            scrollView.bounces = false
        case .changed:
            interactor.shouldFinish = progress > percentThreshold
            interactor.update(progress)
        case .cancelled:
            interactor.hasStarted = false
            interactor.cancel()
            scrollView.bounces = true
        case .ended:
            interactor.hasStarted = false
            interactor.shouldFinish ? interactor.finish() : interactor.cancel()
            scrollView.bounces = true
        default:
            break
        }
    }
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard gestureRecognizer == dismissPanGestureRecognizer else { return true }
        let isRegular = traitCollection.horizontalSizeClass == .regular && traitCollection.verticalSizeClass == .regular
        return scrollView.contentOffset.y == 0 && !isRegular ? true : false
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
