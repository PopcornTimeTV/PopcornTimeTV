

import Foundation
import class PopcornKit.NetworkManager

class MediaViewController: MainViewController {
    
    var currentGenre = NetworkManager.Genres.all {
        didSet {
            collectionViewController.currentPage = 1
            didRefresh(collectionView: collectionView!)
        }
    }
    
    @IBAction func showGenres(_ sender: Any) {
        let controller = UIAlertController(title: "Select a genre to filter by".localized, message: nil, preferredStyle: .actionSheet, blurStyle: .dark)
        
        let handler: ((UIAlertAction) -> Void) = { (handler) in
            self.currentGenre = NetworkManager.Genres.array.first(where: {$0.string == handler.title!})!
            if self.currentGenre == .all {
                self.navigationItem.title = (self is MoviesViewController ? "Movies" : "Shows").localized
            } else {
               self.navigationItem.title = self.currentGenre.string
            }
            
        }
        
        NetworkManager.Genres.array.forEach {
            controller.addAction(UIAlertAction(title: $0.string, style: .default, handler: handler))
        }
        
        controller.addAction(UIAlertAction(title: "Cancel".localized, style: .cancel, handler: nil))
        controller.preferredAction = controller.actions.first(where: {$0.title == self.currentGenre.string})
        
        if let barButtonItem = sender as? UIBarButtonItem {
            controller.popoverPresentationController?.barButtonItem = barButtonItem
        }
        
        present(controller, animated: true)
    }
}
