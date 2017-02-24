

import Foundation
import PopcornKit

extension ShowDetailViewController: SeasonPickerViewControllerDelegate {
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        ThemeSongManager.shared.playShowTheme(Int(show.tvdbId)!)
    }
}
