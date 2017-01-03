

import Foundation
import PopcornKit
import ColorArt

extension MovieDetailViewController: UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2
    }
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return section == 0 ? currentItem.related.count : currentItem.actors.count
    }
    
    func collectionView(_ collectionView: UICollectionView,layout collectionViewLayout: UICollectionViewLayout,sizeForItemAt indexPath: IndexPath) -> CGSize {
        var items = 1
        while (collectionView.bounds.width/CGFloat(items))-8 > 195 {
            items += 1
        }
        let width = (collectionView.bounds.width/CGFloat(items))-8
        let ratio = width/195.0
        let height = 280.0 * ratio
        return CGSize(width: width, height: height)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if &classContext == context && keyPath == "frame" {
            collectionView.collectionViewLayout.invalidateLayout()
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell: UICollectionViewCell
        if indexPath.section == 0 {
            cell = {
                let coverCell = collectionView.dequeueReusableCell(withReuseIdentifier: "relatedCell", for: indexPath) as! CoverCollectionViewCell
                let movie = currentItem.related[indexPath.row]
                coverCell.titleLabel.text = movie.title
                coverCell.yearLabel.text = movie.year
                if let image = movie.smallCoverImage,
                    let url = URL(string: image) {
                    coverCell.coverImage.af_setImage(withURL: url, placeholderImage: UIImage(named: "Movie Placeholder"))
                }
                coverCell.watched = WatchedlistManager<Movie>.movie.isAdded(movie.id)
                return coverCell
            }()
        } else {
            cell = collectionView.dequeueReusableCell(withReuseIdentifier: "castCell", for: indexPath)
            let imageView = cell.viewWithTag(1) as! UIImageView
            if let image = currentItem.actors[indexPath.row].smallImage,
                let url = URL(string: image) {
                imageView.af_setImage(withURL: url, placeholderImage: UIImage(named: "Movie Placeholder"))
            } else {
                imageView.image = UIImage(named: "Movie Placeholder")
            }
            imageView.layer.cornerRadius = self.collectionView(collectionView, layout: collectionView.collectionViewLayout, sizeForItemAt: indexPath).width/2
            (cell.viewWithTag(2) as! UILabel).text = currentItem.actors[indexPath.row].name
            (cell.viewWithTag(3) as! UILabel).text = currentItem.actors[indexPath.row].characterName
        }
        return cell
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        if let coverImageAsString = currentItem.mediumCoverImage,
            let backgroundImageAsString = currentItem.largeBackgroundImage {
            backgroundImageView.af_setImage(withURLRequest: URLRequest(url: URL(string: traitCollection.horizontalSizeClass == .compact ? coverImageAsString : backgroundImageAsString)!), placeholderImage: UIImage(named: "Movie Placeholder"), imageTransition: .crossDissolve(animationLength), completion: {
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
            self.collectionView.collectionViewLayout.invalidateLayout()
        })
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionElementKindSectionHeader {
            return {
                let element = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "header", for: indexPath)
                let label = (element.viewWithTag(1) as! UILabel)
                label.text = nil
                if indexPath.section == 0 && !currentItem.related.isEmpty {
                    label.text = "RELATED"
                } else if indexPath.section == 1 && !currentItem.actors.isEmpty {
                    label.text = "CAST"
                }
                return element
                }()
        }
        return collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "footer", for: indexPath)
    }
}
