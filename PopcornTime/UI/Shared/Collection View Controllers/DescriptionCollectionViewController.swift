

import Foundation

class DescriptionCollectionViewController: ResponsiveCollectionViewController, UICollectionViewDelegateFlowLayout {
    
    var headerTitle: String?
    var sizingCell: DescriptionCollectionViewCell?
    
    var dataSource: [(key: Any, value: String)] = [("", "")]
    
    var isDark = true {
        didSet {
            guard isDark != oldValue else { return }
            
            collectionView?.reloadData()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView?.register(UINib(nibName: String(describing: DescriptionCollectionViewCell.self), bundle: nil), forCellWithReuseIdentifier: "cell")
    }
    
    override func collectionView(_ collectionView: UICollectionView, layout: UICollectionViewFlowLayout, didChangeToSize size: CGSize) {
        var estimatedContentHeight: CGFloat = 0.0
        
        for section in 0..<collectionView.numberOfSections {
            
            let headerSize = self.collectionView(collectionView, layout: layout, referenceSizeForHeaderInSection: section)
        
            estimatedContentHeight += headerSize.height
            
            let numberOfCells = collectionView.numberOfItems(inSection: section)
            
            for item in 0..<numberOfCells {
                let itemSize = self.collectionView(collectionView, layout: layout, sizeForItemAt: IndexPath(item: item, section: section))
                estimatedContentHeight += itemSize.height + layout.minimumLineSpacing
            }
        }
        
        super.collectionView(collectionView, layout: layout, didChangeToSize: CGSize(width: collectionView.bounds.width, height: estimatedContentHeight))
    }
    
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! DescriptionCollectionViewCell
        
        let data = dataSource[indexPath.row]
        
        if let text = data.key as? String {
            cell.keyLabel.text = text
        } else if let attributedText = data.key as? NSAttributedString {
            cell.keyLabel.attributedText = attributedText
        }
        cell.valueLabel.text = data.value
        cell.isDark = isDark
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let data = dataSource[indexPath.row]
        
        sizingCell = sizingCell ?? .fromNib()
        
        if let text = data.key as? String {
            sizingCell?.keyLabel.text = text
        } else if let attributedText = data.key as? NSAttributedString {
            sizingCell?.keyLabel.attributedText = attributedText
        }
        sizingCell?.valueLabel.text = data.value
        
        sizingCell?.setNeedsLayout()
        sizingCell?.layoutIfNeeded()
        
        let maxWidth   = collectionView.bounds.width
        let targetSize = CGSize(width: maxWidth, height: 0)
        
        return sizingCell?.contentView.systemLayoutSizeFitting(targetSize, withHorizontalFittingPriority: UILayoutPriorityRequired, verticalFittingPriority: UILayoutPriorityFittingSizeLevel) ?? .zero
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return headerTitle == nil ? .zero : CGSize(width: collectionView.bounds.width, height: 50)
    }
    
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionElementKindSectionHeader, let title = headerTitle {
            let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "header", for: indexPath)
            
            let titleLabel = view.viewWithTag(1) as? UILabel
            titleLabel?.text = title
            titleLabel?.textColor = isDark ? .white : .black
            
            return view
        }
        return super.collectionView(collectionView, viewForSupplementaryElementOfKind: kind, at: indexPath)
    }
}
