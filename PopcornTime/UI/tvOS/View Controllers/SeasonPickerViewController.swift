

import Foundation
import PopcornKit

protocol SeasonPickerViewControllerDelegate: class {
    func change(to season: Int)
}

class SeasonPickerViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    @IBOutlet var showLabel: UILabel!
    @IBOutlet var backgroundImageView: UIImageView!
    @IBOutlet var collectionView: UICollectionView!
    
    @IBOutlet var collectionViewContainerViewWidthConstraint: NSLayoutConstraint!
    
    private var seasons: [(number: Int, image: String?)] = []
    
    var currentSeason: Int!
    var show: Show!
    
    weak var delegate: SeasonPickerViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        showLabel.text = show.title
        
        if let image = show.smallBackgroundImage, let url = URL(string: image) {
            backgroundImageView.af_setImage(withURL: url)
        }
        
        seasons = show.seasonNumbers.flatMap({($0, nil)})
        
        for (index, season) in show.seasonNumbers.enumerated() {
            TMDBManager.shared.getSeasonPoster(ofShowWithImdbId: show.id, orTMDBId: show.tmdbId, season: season) { (tmdb, image, _) in
                if let tmdb = tmdb { self.show.tmdbId = tmdb }
                self.seasons[index] = (season, image ?? self.show.largeCoverImage)
                self.collectionView.reloadData()
            }
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            
            let items = CGFloat(collectionView.numberOfItems(inSection: 0))
            
            let sectionInset = layout.sectionInset.left + layout.sectionInset.right
            let cellWidth = self.collectionView(collectionView, layout: layout, sizeForItemAt: IndexPath(item: 0, section: 0)).width * items
            let spacing = layout.minimumLineSpacing * (items - 1)
            
            let width = spacing + cellWidth + sectionInset
            
            collectionViewContainerViewWidthConstraint.constant = width > view.bounds.width ? view.bounds.width : width
        }
    }
    
    func indexPathForPreferredFocusedView(in collectionView: UICollectionView) -> IndexPath? {
        if let item = seasons.index(where: {$0.number == currentSeason}) {
            return IndexPath(item: item, section: 0)
        }
        return nil
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return seasons.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! CoverCollectionViewCell
        
        let season = seasons[indexPath.row]
        
        cell.titleLabel.text = "Season \(season.number)"
        
        if let image = season.image, let url = URL(string: image) {
            cell.coverImageView.af_setImage(withURL: url)
        } else {
            cell.coverImageView.image = UIImage(named: "Episode Placeholder")
        }
    
        cell.hidesTitleLabelWhenUnfocused = false
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        delegate?.change(to: seasons[indexPath.row].number)
        dismiss(animated: true)
    }

    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 300, height: 550)
    }
}
