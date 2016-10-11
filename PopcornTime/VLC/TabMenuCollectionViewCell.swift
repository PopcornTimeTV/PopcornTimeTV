

import UIKit

enum TabMenuCollectionViewType {
    case unknown
    case subtitle
    case audio
    case subColor
    case subFont
    case subBackground
}

protocol TabMenuCollectionViewCellDelegate: class {
    func cellDidBecomeSelected(_ cell: TabMenuCollectionViewCell)
}

class TabMenuCollectionViewCell: UICollectionViewCell {
    @IBOutlet var nameLabel: UILabel!
    weak var delegate: TabMenuCollectionViewCellDelegate?
    var collectionViewType: TabMenuCollectionViewType!
    
    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        super.didUpdateFocus(in: context, with: coordinator)
        if self == context.nextFocusedView { delegate?.cellDidBecomeSelected(self) }
    }
}
