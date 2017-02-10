

import Foundation

extension Array where Element: Hashable {
    
    /**
     Remove duplicates from an array while preserving the order. Array elements must conform to protocol, `Hashable`
     
     - Parameter source: The array.
     
     - Returns: Unique and sorted array.
     */
    func unique() -> Array {
        var buffer = [Element]()
        var added = Set<Element>()
        for elem in self {
            if !added.contains(elem) {
                buffer.append(elem)
                added.insert(elem)
            }
        }
        return buffer
    }
    
    mutating func uniqued() {
        self = unique()
    }
    
    /**
     Returns a new array containing the elements of this array that are not common with the given array.
    
     In the following example, the `goodFriends` array is made up of the
     elements of the `friends` array excluding the `badFriends` array:
    
         let friends = ["Alicia", "Bethany", "Chris", "Diana", "Eric"]
         let badFriends = ["Bethany", "Chris"]
         let goodFriends = friends.removing(badFriends)
         print(goodFriends)
         // Prints "["Alicia", "Diana", "Eric"]"
    
     - Parameter elements: Sub-elements of this array.
     - Returns: A new array.
     */
    func removing(elements: [Element]) -> Array {
        return Array(Set(self).subtracting(Set(elements)))
    }
    
    /**
     Returns a new array containing the elements of the previous array plus the passed in items. Non mutating.
     
     - Parameter items: The items you wish to have appended to a `mutableCopy()` of `self`.
     
     - Returns: A new array with the items appended.
     */
    func appending(_ items: Element...) -> [Element] {
        var new = self
        new.append(contentsOf: items)
        return new
    }
}
