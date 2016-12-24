

import Foundation

/**
 Remove duplicates from an array while preserving the order. Array elements must conform to protocol, `Hashable`
 
 - Parameter source: The array.
 
 - Returns: Unique and sorted array.
 */
func unique<S : Sequence, T : Hashable>(source: S) -> [T] where S.Iterator.Element == T {
    var buffer = [T]()
    var added = Set<T>()
    for elem in source {
        if !added.contains(elem) {
            buffer.append(elem)
            added.insert(elem)
        }
    }
    return buffer
}
