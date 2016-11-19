

import UIKit
import AlamofireImage
import PopcornKit

protocol EpisodeDetailViewControllerDelegate: class {
    func didDismissViewController(_ vc: EpisodeDetailViewController)
    func playEpisode(_ episode: Episode)
}

class EpisodeDetailViewController: UIViewController, UIGestureRecognizerDelegate {
    
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var episodeAndSeasonLabel: UILabel!
    @IBOutlet var summaryView: UITextView!
    @IBOutlet var infoLabel: UILabel!
    
    @IBOutlet var qualityButton: UIButton!
    @IBOutlet var playNowButton: BorderButton!
    @IBOutlet var subtitlesButton: UIButton!
    
    @IBOutlet var scrollView: UIScrollView!
    @IBOutlet var torrentHealth: CircularView!
    @IBOutlet var backgroundImageView: UIImageView!
    
    @IBOutlet var heightConstraint: NSLayoutConstraint!
    
    var currentItem: Episode?
    
    weak var delegate: EpisodeDetailViewControllerDelegate?
    var interactor: EpisodeDetailPercentDrivenInteractiveTransition?
    
    override var navigationController: UINavigationController? {
        return splitViewController?.viewControllers.first?.navigationController
    }
    
    override var tabBarController: UITabBarController? {
        return splitViewController?.viewControllers.first?.tabBarController
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if transitionCoordinator?.viewController(forKey: UITransitionContextViewControllerKey.to) == self.presentingViewController {
            delegate?.didDismissViewController(self)
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let adjustForTabbarInsets = tabBarController?.tabBar.frame.height ?? 0
        scrollView.contentInset.bottom = adjustForTabbarInsets
        scrollView.contentInset.top = 0.0
        scrollView.scrollIndicatorInsets.bottom = adjustForTabbarInsets
        heightConstraint.constant = UIScreen.main.bounds.height * 0.35
        preferredContentSize = scrollView.contentSize
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        defer {
            scrollView.setNeedsLayout()
            scrollView.layoutIfNeeded()
            preferredContentSize = scrollView.contentSize
        }
        
        guard let currentItem = currentItem else {
            let background = Bundle.main.loadNibNamed("TableBackgroundView", owner: self, options: nil)?.first as! TableBackgroundView
            background.frame = view.bounds
            background.autoresizingMask = [.flexibleHeight, .flexibleWidth]
            background.backgroundColor = UIColor(red: 30.0/255.0, green: 30.0/255.0, blue: 30.0/255.0, alpha: 1.0)
            view.insertSubview(background, aboveSubview: view)
            background.setUpView(image: UIImage(named: "AirTV")!.withRenderingMode(.alwaysTemplate), description: "No episode selected")
            background.imageView.tintColor = UIColor.darkGray
            return
        }
        
        titleLabel.text = currentItem.title
        
        var season = String(currentItem.season)
        season = season.characters.count == 1 ? "0" + season : season
        var episode = String(currentItem.episode)
        episode = episode.characters.count == 1 ? "0" + episode : episode
        episodeAndSeasonLabel.text = "S\(season)E\(episode)"
        summaryView.text = currentItem.summary
        
        if let date = currentItem.firstAirDate {
            infoLabel.text = "Aired: " + DateFormatter.localizedString(from: date, dateStyle: .medium, timeStyle: .none)
        }
        
        qualityButton.isUserInteractionEnabled = currentItem.torrents.count > 1
        self.currentItem!.currentTorrent = currentItem.torrents.first(where: {$0.quality == UserDefaults.standard.string(forKey: "preferredQuality")}) ?? currentItem.torrents.first
        if let torrent = self.currentItem!.currentTorrent {
            qualityButton.setTitle("\(torrent.quality! + (currentItem.torrents.count > 1 ? " ▾" : ""))", for: .normal)
        } else {
            qualityButton.setTitle("Error loading torrents.", for: .normal)
        }
        
        playNowButton.isEnabled = self.currentItem!.currentTorrent?.url != nil
        torrentHealth.backgroundColor = self.currentItem!.currentTorrent?.health.color
        
        getSubtitles(forMedia: currentItem, id: currentItem.id) { [weak self] (subtitles, error) in
            guard let `self` = self else { return }
            guard error == nil else { self.subtitlesButton.setTitle("Error loading subtitles", for: .normal); return }
            self.currentItem?.subtitles = subtitles
            guard !subtitles.isEmpty else { self.subtitlesButton.setTitle("No Subtitles Available", for: .normal); return }
            
            
            
            self.subtitlesButton.setTitle("None ▾", for: .normal)
            self.subtitlesButton.isUserInteractionEnabled = true
            
            if let preferredSubtitle = SubtitleSettings().language {
                let languages = subtitles.flatMap({$0.language})
                guard let index = languages.index(where: {$0 == languages.first(where: {$0 == preferredSubtitle})}) else { return }
                let subtitle = self.currentItem!.subtitles![index]
                self.currentItem!.currentSubtitle = subtitle
                self.subtitlesButton.setTitle(subtitle.language + " ▾", for: .normal)
            }
        }
        
        TMDBManager.shared.getEpisodeScreenshots(forShowWithImdbId: currentItem.show.id, orTMDBId: currentItem.show.tmdbId, season: currentItem.season, episode: currentItem.episode, completion: { (tmdb, image, error) in
            if let tmdb = tmdb { self.currentItem!.show.tmdbId = tmdb }
            if let image = image,
                let url = URL(string: image) {
                self.currentItem!.largeBackgroundImage = image
                self.backgroundImageView!.af_setImage(withURL: url, placeholderImage: UIImage(named: "Placeholder"), imageTransition: .crossDissolve(animationLength))
            }
        })
    }
    
    func getSubtitles(forMedia media: Media, id: String, completion: @escaping ([Subtitle], NSError?) -> Void) {
        if let episode = media as? Episode, !id.hasPrefix("tt") {
            TraktManager.shared.getEpisodeMetadata(episode.show.id, episodeNumber: episode.episode, seasonNumber: episode.season, completion: { [weak self] (tvdb, imdb, error) in
                if let imdb = imdb { self?.getSubtitles(forMedia: media, id: imdb, completion: completion) } else if error == nil {
                    SubtitlesManager.shared.search(episode) { (subtitles, error) in
                        completion(subtitles, error)
                    }
                }
            })
        } else {
            SubtitlesManager.shared.search(imdbId: id) { (subtitles, error) in
                completion(subtitles, error)
            }
        }
    }
    
    @IBAction func changeQuality(_ sender: UIButton) {
        let quality = UIAlertController(title: "Select Quality", message: nil, preferredStyle: .actionSheet)
        for torrent in currentItem!.torrents {
            quality.addAction(UIAlertAction(title: "\(torrent.quality!) \(torrent.size ?? "")", style: .default, handler: { action in
                self.currentItem?.currentTorrent = torrent
                self.playNowButton?.isEnabled = self.currentItem?.currentTorrent?.url != nil
                self.qualityButton?.setTitle("\(torrent.quality!) ▾", for: .normal)
                self.torrentHealth.backgroundColor = torrent.health.color
            }))
        }
        quality.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        quality.popoverPresentationController?.sourceView = sender
        present(quality, animated: true, completion: nil)
    }
    
    @IBAction func changeSubtitle(_ sender: UIButton) {
        let controller = UIAlertController(title: "Select Subtitle", message: nil, preferredStyle: .actionSheet)
        guard var currentItem = currentItem, let subtitles = currentItem.subtitles, !subtitles.isEmpty else { return }
        
        let handler: (UIAlertAction) -> Void = { (action) in
            guard let index = subtitles.index(where: {$0.language == action.title }),
                let currentSubtitle = subtitles.first(where: {$0 == subtitles[index]}) else { return }
            currentItem.currentSubtitle = currentSubtitle
            self.subtitlesButton.setTitle(currentSubtitle.language + " ▾", for: .normal)
        }
        controller.addAction(UIAlertAction(title: "None", style: .default, handler: { (action) in
            currentItem.currentSubtitle = nil
            self.subtitlesButton.setTitle("None ▾", for: .normal)
        }))
        
        for subtitle in subtitles.flatMap({$0.language}) {
            controller.addAction(UIAlertAction(title: subtitle, style: .default, handler: handler))
        }
        
        controller.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        let preferredLanguage = SubtitleSettings().language
        controller.preferredAction = controller.actions.first(where: {$0.title == preferredLanguage})
        controller.popoverPresentationController?.sourceView = sender
        present(controller, animated: true, completion: nil)
    }
    
    @IBAction func playEpisode() {
        dismiss(animated: false, completion: nil)
        delegate?.playEpisode(currentItem!)
    }
    
    @IBAction func handleGesture(_ sender: UIPanGestureRecognizer) {
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
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return scrollView.contentOffset.y == 0 ? true : false
    }
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return .lightContent
    }
}
