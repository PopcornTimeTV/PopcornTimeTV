

import Foundation

public func < (left: NSDate, right: NSDate) -> Bool {
    return left.compare(right) == NSComparisonResult.OrderedAscending
}

public func == (left: NSDate, right: NSDate) -> Bool {
    return left.isEqualToDate(right)
}

extension NSDate : Comparable {}

extension NSDate {
    func matches(year: Int, month: Int, dayOfMonth: Int, timeZone: NSTimeZone = NSTimeZone(forSecondsFromGMT:0), calendarIdentifier: String = NSCalendarIdentifierGregorian) -> Bool {
        let calendar = NSCalendar(identifier:calendarIdentifier)!
        calendar.timeZone = timeZone
        let components = calendar.components([.Year, .Month, .Day], fromDate:self)
        return components.year == year && components.month == month && components.day == dayOfMonth
    }
}

extension NSDate {
    func nextDay () -> NSDate {
        let calendar = NSCalendar.currentCalendar()
        let components = NSDateComponents()
        components.day = 1
        return calendar.dateByAddingComponents(components, toDate: self, options: NSCalendarOptions())!
    }

    func previousDay () -> NSDate {
        let calendar = NSCalendar.currentCalendar()
        let components = NSDateComponents()
        components.day = -1
        return calendar.dateByAddingComponents(components, toDate: self, options: NSCalendarOptions())!
    }

    func previousWeek () -> NSDate {
        let calendar = NSCalendar.currentCalendar()
        let components = NSDateComponents()
        components.day = -7
        return calendar.dateByAddingComponents(components, toDate: self, options: NSCalendarOptions())!
    }

    func previousMonth() -> NSDate {
        let calendar = NSCalendar.currentCalendar()
        let components = NSDateComponents()
        components.month = -1
        return calendar.dateByAddingComponents(components, toDate: self, options: NSCalendarOptions())!
    }
}
