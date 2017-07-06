

import Foundation

extension ShowDetailViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.rightBarButtonItems?.removeFirst()
        moreSeasonsButton?.isHidden = show.seasonNumbers.count == 1
    }
    
    @IBAction func changeSeason(_ sender: UIButton) {
        let controller = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet, blurStyle: .dark)
        
        let handler: (UIAlertAction) -> Void = { [unowned self] action in
            guard
                let title = action.title,
                let string = title.components(separatedBy: "Season".localized + " ").last,
                let season = Int(string)
                else {
                    return
            }
            
            self.change(to: season)
        }
        
        show.seasonNumbers.forEach {
            controller.addAction(UIAlertAction(title: "Season".localized + " \($0)", style: .default, handler: handler))
        }
        
        controller.addAction(UIAlertAction(title: "Cancel".localized, style: .cancel, handler: nil))
        controller.preferredAction = controller.actions.first(where: {$0.title == "Season".localized + " \(self.currentSeason)"})
        controller.popoverPresentationController?.sourceView = sender
        
        present(controller, animated: true)
    }
}
