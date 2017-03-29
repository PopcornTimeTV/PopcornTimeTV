

import Foundation


class ResponsiveCollectionViewController: UICollectionViewController {
    
    private var classContext = 0
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if let collectionView = collectionView, let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            self.collectionView(collectionView, layout: layout, didChangeToSize: collectionView.systemLayoutSizeFitting(UILayoutFittingCompressedSize))
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout: UICollectionViewFlowLayout, didChangeToSize size: CGSize) {
        
        let section = layout.sectionInset
        let content = collectionView.contentInset
        
        let height  = size.height + section.top + section.bottom + content.bottom + content.top
        let size = CGSize(width: size.width, height: collectionView.numberOfItems(inSection: 0) == 0 ? 0 : height)
        
        
        preferredContentSize = size
    }
    
    override dynamic func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        guard previousTraitCollection != nil else { return }
        collectionView?.performBatchUpdates(nil)
        collectionView?.subviews.filter({$0 is UICollectionReusableView}).forEach({$0.layoutSubviews()})
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if let keyPath = keyPath, keyPath == "frame" && context == &classContext {
            collectionView?.performBatchUpdates(nil)
            collectionView?.subviews.filter({$0 is UICollectionReusableView}).forEach({$0.layoutSubviews()})
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        collectionView?.addObserver(self, forKeyPath: "frame", options: .new, context: &classContext)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        do { try collectionView?.remove(self, for: "frame", in: &classContext) } catch {}
    }
}
