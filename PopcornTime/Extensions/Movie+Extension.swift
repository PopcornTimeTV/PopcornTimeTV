

import Foundation
import PopcornKit

extension Movie {
    
    private func secondsToHoursMinutesSeconds(_ seconds: Int) -> (Int, Int, Int) {
        return (seconds / 3600, (seconds % 3600) / 60, (seconds % 3600) % 60)
    }
    
    var formattedRuntime: String {
        let (hours, minutes, _) = secondsToHoursMinutesSeconds(runtime * 60)
        
        let formatted = "\(hours) h"

        return minutes > 0 ? formatted + " \(minutes) min" : formatted
    }
}
