

import Foundation

extension String {
    
    func truncateToSize(size: CGSize,
                        ellipsesString: String,
                        trailingText: String,
                        attributes: [NSAttributedString.Key : Any],
                        trailingTextAttributes: [NSAttributedString.Key : Any]) -> NSAttributedString {
        
        if !willFit(to: size, attributes: attributes) {
            let indexOfLastCharacterThatFits = indexThatFits(size: size,
                                                             ellipsesString: ellipsesString,
                                                             trailingText: trailingText,
                                                             attributes: attributes,
                                                             minIndex: 0,
                                                             maxIndex: count)
            
            let range = startIndex..<index(startIndex, offsetBy: indexOfLastCharacterThatFits)
            let substring = self[range]
            let attributedString = NSMutableAttributedString(string: substring + ellipsesString, attributes: attributes)
            let attributedTrailingString = NSAttributedString(string: trailingText, attributes: trailingTextAttributes)
            attributedString.append(attributedTrailingString)
            return attributedString
            
        }
        else {
            return NSAttributedString(string: self, attributes: attributes)
        }
    }
    
    func willFit(to size: CGSize,
                 ellipsesString: String = "",
                 trailingText: String = "",
                 attributes: [NSAttributedString.Key : Any]) -> Bool {
        
        let text = (self + ellipsesString + trailingText) as NSString
        let boundedSize = CGSize(width: size.width, height: .greatestFiniteMagnitude)
        let options: NSStringDrawingOptions = [.usesLineFragmentOrigin, .usesFontLeading]
        let boundedRect = text.boundingRect(with: boundedSize, options: options, attributes: attributes, context: nil)
        return boundedRect.height <= size.height
    }
    
    // MARK: - Private
    
    private func indexThatFits(size: CGSize,
                               ellipsesString: String,
                               trailingText: String,
                               attributes: [NSAttributedString.Key : Any],
                               minIndex: Int,
                               maxIndex: Int) -> Int {
        
        guard maxIndex - minIndex != 1 else { return minIndex }
        
        let midIndex = (minIndex + maxIndex) / 2
        let range = startIndex..<index(startIndex, offsetBy: midIndex)
        let substring = String(self[range])
        
        if !substring.willFit(to: size, ellipsesString: ellipsesString, trailingText: trailingText, attributes: attributes) {
            return indexThatFits(size: size,
                                 ellipsesString: ellipsesString,
                                 trailingText: trailingText,
                                 attributes: attributes,
                                 minIndex: minIndex,
                                 maxIndex: midIndex)
        }
        else {
            return indexThatFits(size: size,
                                 ellipsesString: ellipsesString,
                                 trailingText: trailingText,
                                 attributes: attributes,
                                 minIndex: midIndex,
                                 maxIndex: maxIndex)
            
        }
    }
}
