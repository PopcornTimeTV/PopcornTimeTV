

import Foundation

extension ShowDetailViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        moreSeasonsButton.isHidden = show.seasonNumbers.count == 1
    }
    
    @IBAction func changeSeason(_ sender: UIButton) {
        let controller = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet, blurStyle: .dark)
        
        let handler: (UIAlertAction) -> Void = { [unowned self] action in
            guard let title = action.title,
                let string = title.components(separatedBy: "Season ").last, let season = Int(string) else { return }
            self.change(to: season)
        }
        
        show.seasonNumbers.forEach({
            controller.addAction(UIAlertAction(title: "Season \($0)", style: .default, handler: handler))
        })
        
        controller.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        controller.preferredAction = controller.actions.first(where: {$0.title == "Season \(self.currentSeason)"})
        controller.popoverPresentationController?.sourceView = sender
        
        present(controller, animated: true)
    }
}
