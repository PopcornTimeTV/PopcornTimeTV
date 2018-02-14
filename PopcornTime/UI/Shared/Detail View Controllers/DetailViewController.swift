

import Foundation
import UIKit
import AlamofireImage
import PopcornTorrent
import PopcornKit

protocol SegueHandlerType {
    associatedtype SegueIdentifier: RawRepresentable
}

extension SegueHandlerType where Self: UIViewController, SegueIdentifier.RawValue == String {

    func performSegueWithIdentifier(segueIdentifier: SegueIdentifier, sender: AnyObject?) {
        performSegue(withIdentifier: segueIdentifier.rawValue, sender: sender)
    }

    func segueIdentifier(for segue: UIStoryboardSegue) -> SegueIdentifier {

        guard let identifier = segue.identifier,
            let segueIdentifier = SegueIdentifier(rawValue: identifier) else {
                fatalError("Invalid segue identifier \(String(describing: segue.identifier)).") }

        return segueIdentifier
    }
}

final class DetailViewController: UIViewController, CollectionViewControllerDelegate, UIScrollViewDelegate, SegueHandlerType {

    enum SegueIdentifier: String {

        case embedAccessibility
        case embedEpisodes
        case embedItem
        case embedPeople
        case embedRelated
        case showCastDevices
    }

    #if os(iOS)

    @IBOutlet var castButton: CastIconButton?
    @IBOutlet var watchlistButton: UIButton!
    @IBOutlet var watchedButton: UIButton!

    @IBOutlet var moreSeasonsButton: UIButton?
    @IBOutlet var seasonsLabel: UILabel!

    var headerHeight: CGFloat = 0 {
        didSet {
            scrollView.contentInset.top = headerHeight
        }
    }

    #elseif os(tvOS)

    var seasonsLabel: UILabel {
        get {
            return itemViewController.titleLabel
        } set (label) {
            itemViewController.titleLabel = label
        }
    }

    var watchlistButton: TVButton! {
        get {
            return itemViewController.watchlistButton
        } set (button) {
            itemViewController.watchlistButton = button
        }
    }
    var watchedButton: TVButton! {
        get {
            return itemViewController.watchedButton
        } set (button) {
            itemViewController.watchedButton = button
        }
    }

    #endif

    // tvOS Exclusive
    @IBOutlet var titleImageView: UIImageView?
    @IBOutlet var titleLabel: UILabel?
    @IBOutlet var backgroundVisualEffectView: UIVisualEffectView?

    // iOS Exclusive
    @IBOutlet var gradientView: GradientView?

    @IBOutlet var scrollView: UIScrollView!
    @IBOutlet var infoStackView: UIStackView!
    @IBOutlet var backgroundImageView: UIImageView!

    @IBOutlet var peopleHeader:  UILabel!
    @IBOutlet var relatedHeader: UILabel!
    @IBOutlet var peopleBottomConstraint:  NSLayoutConstraint!
    @IBOutlet var relatedBottomConstraint: NSLayoutConstraint!
    @IBOutlet var peopleTopConstraint: NSLayoutConstraint!
    @IBOutlet var relatedTopConstraint: NSLayoutConstraint!

    @IBOutlet var compactConstraints: [NSLayoutConstraint] = []
    @IBOutlet var regularConstraints: [NSLayoutConstraint] = []

    // MARK: - Container view controllers

    var itemViewController: ItemViewController!
    var relatedCollectionViewController: CollectionViewController!
    var peopleCollectionViewController: CollectionViewController!
    var informationDescriptionCollectionViewController: DescriptionCollectionViewController!
    var accessibilityDescriptionCollectionViewController: DescriptionCollectionViewController!
    var episodesCollectionViewController: EpisodesCollectionViewController!

    // MARK: - Container view height constraints

    @IBOutlet var relatedContainerViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet var peopleContainerViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet var episodesContainerViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet var informationContainerViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet var accessibilityContainerViewHeightConstraint: NSLayoutConstraint!

    var currentItem: Media!
    var currentSeason = -1

    @objc var isDark = true {
        didSet {
            guard isDark != oldValue && UIDevice.current.userInterfaceIdiom == .tv else { return }

            childViewControllers.forEach {
                guard $0.responds(to: #selector(getter:DetailViewController.isDark)) else { return }
                $0.setValue(isDark, forKey: "isDark")
            }

            let colorPallete: ColorPallete = isDark ? .light : .dark

            peopleHeader.textColor  = colorPallete.secondary
            relatedHeader.textColor = colorPallete.secondary
            titleLabel?.textColor = colorPallete.primary

            accessibilityDescriptionCollectionViewController.dataSource[0].key = UIImage(named: "SDH")!.colored(colorPallete.primary)!.attributed
        }
    }

    var watchlistButtonImage: UIImage? {
        return itemViewController.watchlistButtonImage
    }

    var watchedButtonImage: UIImage? {
        return itemViewController.watchedButtonImage
    }

    override dynamic func viewDidLoad() {
        super.viewDidLoad()

        #if os(tvOS)

            let focusButtonsGuide = UIFocusGuide()
            view.addLayoutGuide(focusButtonsGuide)

            focusButtonsGuide.topAnchor.constraint(equalTo: itemViewController.view.bottomAnchor).isActive = true
            focusButtonsGuide.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
            focusButtonsGuide.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
            focusButtonsGuide.bottomAnchor.constraint(equalTo: backgroundVisualEffectView!.topAnchor).isActive = true

            focusButtonsGuide.preferredFocusEnvironments = itemViewController.visibleButtons

        #endif

        navigationItem.title = currentItem.title
        titleLabel?.text = currentItem.title

        if let image = currentItem.largeBackgroundImage, let url = URL(string: image) {
            backgroundImageView.af_setImage(withURL: url) { [weak self] response in
                guard
                    let image = response.result.value,
                    let `self` = self,
                    response.result.isSuccess
                    else {
                        return
                }
                self.isDark = image.isDark
            }
        }

        let completion: (String?, NSError?) -> Void = { [weak self] (image, error) in
            guard let image = image, let url = URL(string: image), let `self` = self else { return }
            let imageView = UIImageView(frame: CGRect(origin: .zero, size: CGSize(width: .max, height: 40)))
            imageView.clipsToBounds = true
            imageView.contentMode = .scaleAspectFit
            imageView.af_setImage(withURL: url) { response in
                guard response.result.isSuccess else { return }
                #if os(tvOS)
                    self.titleImageView?.image = response.result.value
                    self.titleLabel?.isHidden = true

                    self.episodesCollectionViewController.titleImageView.image = response.result.value
                    self.episodesCollectionViewController.titleLabel.isHidden = true
                #elseif os(iOS)
                    self.navigationItem.titleView = imageView
                #endif
            }
        }

        if let movie = currentItem as? Movie {
            TMDBManager.shared.getLogo(forMediaOfType: .movies, id: movie.id, completion: completion)
        } else if let show = currentItem as? Show {
            TMDBManager.shared.getLogo(forMediaOfType: .shows, id: show.tvdbId, completion: completion)
        }
    }

    func loadMedia(id: String, completion: @escaping (Media?, NSError?) -> Void) { }

    // MARK: - Collection view controller delegate

    func minItemSize(forCellIn collectionView: UICollectionView, at indexPath: IndexPath) -> CGSize? {
        if collectionView === peopleCollectionViewController.collectionView {
            return UIDevice.current.userInterfaceIdiom == .tv ? CGSize(width: 250, height: 360) : CGSize(width: 108, height: 180)
        } else if collectionView === relatedCollectionViewController.collectionView && UIDevice.current.userInterfaceIdiom == .tv {
            return CGSize(width: 150, height: 304)
        }
        return nil
    }

    // MARK: Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

        switch segueIdentifier(for: segue) {

            case .embedAccessibility:

                if let vc = segue.destination as? DescriptionCollectionViewController {
                    vc.headerTitle = "Accessibility".localized

                    let key = UIImage(named: "SDH")!.colored(isDark ? .white : .black)!.attributed
                    let value = "Subtitles for the deaf and Hard of Hearing (SDH) refer to subtitles in the original language with the addition of relevant non-dialog information.".localized

                    vc.dataSource = [(key, value)]

                    accessibilityDescriptionCollectionViewController = vc
                }

            case .embedEpisodes:

                if let vc = segue.destination as? EpisodesCollectionViewController {
                    episodesCollectionViewController = vc
                }

            case .embedItem:

                if let vc = segue.destination as? ItemViewController {

                    itemViewController = vc
                    itemViewController.media = currentItem
                    vc.view.translatesAutoresizingMaskIntoConstraints = false
                }

            case .showCastDevices:

                #if os(iOS)
                if let vc = segue.destination as? UINavigationController, vc.viewControllers.first is GoogleCastTableViewController, let sender = sender as? CastIconButton {
                    vc.popoverPresentationController?.sourceRect = sender.bounds
                }
                #endif

            case .embedPeople, .embedRelated:

                if let vc = segue.destination as? CollectionViewController {
                    vc.delegate = self

                    let layout = vc.collectionView?.collectionViewLayout as? UICollectionViewFlowLayout
                    layout?.scrollDirection = .horizontal
                    layout?.minimumLineSpacing = 48
                    layout?.sectionInset.top = 0
                    layout?.sectionInset.bottom = 0
                }
        }
    }

    // MARK: Container view size changes

    override func preferredContentSizeDidChange(forChildContentContainer container: UIContentContainer) {

        let height  = container.preferredContentSize.height
        let vc      = container as? UIViewController
        let margin: CGFloat // Account for anything else on the view (header label etc.).
        let isTv    = UIDevice.current.userInterfaceIdiom == .tv

        switch vc {

            case _ where vc == relatedCollectionViewController:

                // If 0 height is passed in for the collection view, the container view is to be completely hidden.
                margin = height == 0 ? 0 : relatedHeader.frame.height + relatedTopConstraint.constant + relatedBottomConstraint.constant
                relatedContainerViewHeightConstraint.constant = height + margin + (isTv ? 0 : 29)

            case _ where vc == peopleCollectionViewController:

                // If 0 height is passed in for the collection view, the container view is to be completely hidden.
                margin = height == 0 ? 0 : peopleHeader.frame.height + peopleTopConstraint.constant + peopleBottomConstraint.constant
                peopleContainerViewHeightConstraint.constant = height + margin

            case _ where vc == episodesCollectionViewController:

                // If 0 height is passed in for the collection view, the container view is to be completely hidden.
                margin = height == 0 ? 0 : isTv ? 0 : 90
                episodesContainerViewHeightConstraint.constant = height + margin

            case _ where vc == informationDescriptionCollectionViewController:

                informationContainerViewHeightConstraint.constant = height

            case _ where vc == accessibilityDescriptionCollectionViewController:

                accessibilityContainerViewHeightConstraint.constant = height

            default: fatalError("unhandled content size for controller \(vc)"); break;
        }
    }
}

