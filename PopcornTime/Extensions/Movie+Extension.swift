

import Foundation
import struct PopcornKit.Show
import struct PopcornKit.Movie

private func secondsToHoursMinutesSeconds(_ seconds: Int) -> (Int, Int, Int) {
    return (seconds / 3600, (seconds % 3600) / 60, (seconds % 3600) % 60)
}

extension Movie {
    
    var formattedRuntime: String {
        let (hours, minutes, _) = secondsToHoursMinutesSeconds(runtime * 60)
        
        let formatted = hours > 0 ? "\(hours) h " : ""

        return minutes > 0 ? formatted + "\(minutes) min" : formatted
    }
    
}

extension Show {
    
    var formattedRuntime: String? {
        guard let runtime = runtime else { return nil }
        
        let (hours, minutes, _) = secondsToHoursMinutesSeconds(runtime * 60)
        
        let formatted = hours > 0 ? "\(hours) h " : ""
        
        return minutes > 0 ? formatted + "\(minutes) min" : formatted
    }
}
