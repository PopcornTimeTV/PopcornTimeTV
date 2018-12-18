
import UIKit
import struct PopcornKit.Subtitle

class ExtendedSubtitleViewController: UIViewController {
    
    var subtitles = Dictionary<String, [Subtitle]>()
    var currentSubtitle:Subtitle?
    var delegate:SubtitlesViewControllerDelegate?
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        if segue.identifier == "showExtendedTableView"{
            if let destination = segue.destination as? ExtendedSubtitleSelectionTableViewController{
                destination.subtitles = self.subtitles
                destination.currentSubtitle = self.currentSubtitle
                destination.delegate = self.delegate
            }
        }
    }


}
