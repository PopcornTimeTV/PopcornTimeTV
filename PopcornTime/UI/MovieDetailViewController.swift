

import Foundation
import UIKit
//import XCDYouTubeKit
import AlamofireImage
import ColorArt
import FloatRatingView
import PopcornTorrent
import PopcornKit

class MovieDetailViewController: UIViewController, UIViewControllerTransitioningDelegate {

    @IBOutlet var qualityButton: UIButton!
    @IBOutlet var subtitlesButton: UIButton!
    @IBOutlet var playButton: BorderButton!
    @IBOutlet var watchedButton: UIBarButtonItem!
    @IBOutlet var trailerButton: UIButton!
    @IBOutlet var castButton: CastIconBarButtonItem!

    @IBOutlet var scrollView: UIScrollView!
    @IBOutlet var collectionView: UICollectionView!
    
    @IBOutlet var backgroundImageView: UIImageView!
    
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var infoLabel: UILabel!
    
    @IBOutlet var ratingView: FloatRatingView!
    @IBOutlet var summaryView: ExpandableTextView!
    @IBOutlet var torrentHealthView: CircularView!
    @IBOutlet var blurView: UIVisualEffectView!
    @IBOutlet var gradientView: GradientView!
    
    @IBOutlet var regularConstraints: [NSLayoutConstraint]!
    @IBOutlet var compactConstraints: [NSLayoutConstraint]!
    
    var currentItem: Movie!
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.isBackgroundHidden = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.isBackgroundHidden = false
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = currentItem.title
        watchedButton.image = watchedButtonImage
        
        let inset = tabBarController?.tabBar.frame.height ?? 0.0
        scrollView.contentInset.bottom = inset
        scrollView.scrollIndicatorInsets.bottom = inset
        
        titleLabel.text = currentItem.title
        summaryView.text = currentItem.summary
        ratingView.rating = Float(currentItem.rating)
        infoLabel.text = "\(currentItem.year) ● \(currentItem.runtime) min ● \(currentItem.genres.first!.capitalized)"
        playButton.borderColor = SLColorArt(image: backgroundImageView.image).secondaryColor
        trailerButton.isEnabled = currentItem.trailer != nil
        
        if currentItem.torrents.isEmpty {
            PopcornKit.getMovieInfo(currentItem.id, tmdbId: currentItem.tmdbId) { [weak self] (movie, error) in
                guard let movie = movie else { self?.qualityButton?.setTitle("Error loading torrents.", for: .normal); return}
                self?.currentItem = movie
                self?.updateTorrentButton()
            }
        } else {
            updateTorrentButton()
        }
        
        SubtitlesManager.shared.search(imdbId: currentItem.id, completion: { [weak self] (subtitles, error) in
            guard let `self` = self else { return }
            guard error == nil else { self.subtitlesButton.setTitle("Error loading subtitles", for: .normal); return }
            self.currentItem.subtitles = subtitles
            guard !subtitles.isEmpty else { self.subtitlesButton.setTitle("No Subtitles Available", for: .normal); return }
            
            self.subtitlesButton.setTitle("None ▾", for: .normal)
            self.subtitlesButton.isUserInteractionEnabled = true
            
            if let preferredSubtitle = SubtitleSettings().language {
                let languages = subtitles.flatMap({$0.language})
                let index = languages.index{$0 == languages.first(where: {$0 == preferredSubtitle})}
                let subtitle = self.currentItem.subtitles![index!]
                self.currentItem.currentSubtitle = subtitle
                self.subtitlesButton.setTitle(subtitle.language + " ▾", for: .normal)
            }
        })
        
        TraktManager.shared.getRelated(currentItem) { [weak self] (movies, _) in
            guard let `self` = self else { return }
            self.currentItem.related = movies
            //self.collectionView.reloadData()
        }
        TraktManager.shared.getPeople(forMediaOfType: .movies, id: currentItem.id) { [weak self] (actors, crew, _) in
            guard let `self` = self else { return }
            self.currentItem.crew = crew
            self.currentItem.actors = actors
            //self.collectionView.reloadData()
        }
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        if let coverImageAsString = currentItem.mediumCoverImage,
            let backgroundImageAsString = currentItem.largeBackgroundImage {
            backgroundImageView.af_setImage(withURLRequest: URLRequest(url: URL(string: traitCollection.horizontalSizeClass == .compact ? coverImageAsString : backgroundImageAsString)!), placeholderImage: UIImage(named: "Placeholder"), imageTransition: .crossDissolve(animationLength), completion: {
                if let value = $0.result.value {
                    self.playButton.borderColor = SLColorArt(image: value).secondaryColor
                }
            })
        }
        
        for constraint in compactConstraints {
            constraint.priority = traitCollection.horizontalSizeClass == .compact ? 999 : 240
        }
        for constraint in regularConstraints {
            constraint.priority = traitCollection.horizontalSizeClass == .compact ? 240 : 999
        }
        UIView.animate(withDuration: animationLength, animations: {
            self.view.layoutIfNeeded()
            //self.collectionView.collectionViewLayout.invalidateLayout()
        })
    }
    
    var watchedButtonImage: UIImage {
        return WatchedlistManager.movie.isAdded(currentItem.id) ? UIImage(named: "WatchedOn")! : UIImage(named: "WatchedOff")!
    }
    
    func updateTorrentButton() {
        qualityButton.isUserInteractionEnabled = currentItem.torrents.count > 1
        currentItem.currentTorrent = currentItem.torrents.filter({$0.quality == UserDefaults.standard.string(forKey: "preferredQuality")}).first ?? currentItem.torrents.first
        if let torrent = currentItem.currentTorrent, let quality = torrent.quality {
            qualityButton.setTitle("\(quality + (currentItem.torrents.count > 1 ? " ▾" : ""))", for: .normal)
        } else {
            qualityButton.setTitle("No torrents available.", for: .normal)
        }
        torrentHealthView.backgroundColor = currentItem.currentTorrent?.health.color
        playButton.isEnabled = currentItem.currentTorrent?.url != nil
    }
    
    @IBAction func changeQuality(_ sender: UIButton) {
        let quality = UIAlertController(title: "Select Quality", message: nil, preferredStyle: .actionSheet)
        for torrent in currentItem.torrents {
            quality.addAction(UIAlertAction(title: "\(torrent.quality!) \(torrent.size!)", style: .default, handler: { [weak self] action in
                self?.currentItem.currentTorrent = torrent
                self?.playButton.isEnabled = self?.currentItem.currentTorrent?.url != nil
                self?.qualityButton.setTitle("\(torrent.quality!) ▾", for: .normal)
                self?.torrentHealthView.backgroundColor = torrent.health.color
            }))
        }
        quality.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        quality.popoverPresentationController?.sourceView = sender
        present(quality, animated: true, completion: nil)
    }
    
    @IBAction func changeSubtitle(_ sender: UIButton) {
        let controller = UIAlertController(title: "Select Subtitle", message: nil, preferredStyle: .actionSheet)
        guard let subtitles = currentItem.subtitles else { return }
        
        let handler: (UIAlertAction) -> Void = { (action) in
            guard let index = subtitles.index(where: {$0.language == action.title }),
                let currentSubtitle = subtitles.first(where: {$0 == subtitles[index]}) else { return }
            self.currentItem.currentSubtitle = currentSubtitle
        }
        
        for subtitle in subtitles.flatMap({$0.language}) {
            controller.addAction(UIAlertAction(title: subtitle, style: .default, handler: handler))
        }
        
        controller.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        let preferredLanguage = SubtitleSettings().language
        controller.preferredAction = controller.actions.first(where: {$0.title == preferredLanguage})
        controller.popoverPresentationController?.sourceView = sender
        present(controller, animated: true, completion: nil)
    }
}
