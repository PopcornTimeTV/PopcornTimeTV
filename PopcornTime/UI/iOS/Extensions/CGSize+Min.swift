

import Foundation

extension CGSize {
    @nonobjc static let max = CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
    @nonobjc static let min = CGSize(width: CGFloat.leastNormalMagnitude, height: CGFloat.leastNormalMagnitude)
}
