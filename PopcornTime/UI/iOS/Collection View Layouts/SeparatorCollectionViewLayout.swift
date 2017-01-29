

import Foundation

@IBDesignable class SeparatorCollectionViewLayout: UICollectionViewFlowLayout {
    
    @IBInspectable var bottomInset: CGFloat {
        get { return separatorInsets.bottom }
        set { separatorInsets.bottom = newValue }
    }
    @IBInspectable var leftInset: CGFloat {
        get { return separatorInsets.left }
        set { separatorInsets.left = newValue }
    }
    @IBInspectable var rightInset: CGFloat {
        get { return separatorInsets.right }
        set { separatorInsets.right = newValue }
    }
    @IBInspectable var topInset: CGFloat {
        get { return separatorInsets.top }
        set { separatorInsets.top = newValue }
    }
    
    @IBInspectable var separatorColor: UIColor? = .white {
        didSet {
            invalidateLayout()
        }
    }
    
    var separatorInsets: UIEdgeInsets = .zero {
        didSet {
            invalidateLayout()
        }
    }
    
    static let kind = "SeparatorCollectionViewLayoutKind"
    
    override init() {
        super.init()
        sharedSetup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        sharedSetup()
    }
    
    func sharedSetup() {
        register(SeparatorCollectionReusableView.self, forDecorationViewOfKind: SeparatorCollectionViewLayout.kind)
    }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        guard let layoutAttributesArray = super.layoutAttributesForElements(in: rect) else { return nil }
        
        let lineHeight = minimumInteritemSpacing
        var decorationAttributes = [UICollectionViewLayoutAttributes]()
        
        layoutAttributesArray.forEach { (layoutAttributes) in
            let indexPath = layoutAttributes.indexPath
                
            let separatorAttributes = UICollectionViewLayoutAttributes(forDecorationViewOfKind: SeparatorCollectionViewLayout.kind, with: indexPath)
            let cellFrame = layoutAttributes.frame
            
            separatorAttributes.frame = CGRect(x: cellFrame.origin.x + separatorInsets.left, y: cellFrame.origin.y + separatorInsets.top - separatorInsets.bottom, width: cellFrame.width - separatorInsets.right - separatorInsets.left, height: lineHeight)
            separatorAttributes.color = separatorColor
            separatorAttributes.zIndex = 1000
            decorationAttributes.append(separatorAttributes)
        }
        return layoutAttributesArray + decorationAttributes
    }
    
    override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint, withScrollingVelocity velocity: CGPoint) -> CGPoint {
        guard let collectionView = collectionView else { return super.targetContentOffset(forProposedContentOffset: proposedContentOffset, withScrollingVelocity: velocity) }
        
        var offsetAdjustment = CGFloat.greatestFiniteMagnitude
        let horizontalOffset = proposedContentOffset.x + collectionView.contentInset.left
        
        let targetRect = CGRect(x: proposedContentOffset.x, y: 0, width: collectionView.bounds.size.width, height: collectionView.bounds.size.height)
        
        let layoutAttributesArray = super.layoutAttributesForElements(in: targetRect)
        
        layoutAttributesArray?.forEach({ (layoutAttributes) in
            let itemOffset = layoutAttributes.frame.origin.x
            if fabsf(Float(itemOffset - horizontalOffset)) < fabsf(Float(offsetAdjustment)) {
                offsetAdjustment = itemOffset - horizontalOffset
            }
        })
        
        return CGPoint(x: proposedContentOffset.x + offsetAdjustment, y: proposedContentOffset.y)
    }
}

class SeparatorCollectionReusableView: UICollectionReusableView {
    
    override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
        frame = layoutAttributes.frame
        backgroundColor = layoutAttributes.color
    }
}
