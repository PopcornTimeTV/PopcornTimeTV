

import Foundation

class StepperTableViewCell: UITableViewCell {
    
    @IBOutlet var stepper: UIStepper!
    @IBOutlet var titleLabel: UILabel!
    
    override var textLabel: UILabel? {
        return titleLabel
    }
    
    @IBAction func stepperPressed(_ sender: UIStepper) {
        textLabel?.text = (sender.value > 0 ? "+" : "") + "\(sender.value)"
        
        let parent = parentViewController as? OptionsTableViewController
        let indexPath = parent?.tableView?.indexPath(for: self)
        
        if indexPath?.section == 0 {
           parent?.delegate?.didSelectAudioDelay(Int(sender.value))
        } else {
            parent?.delegate?.didSelectSubtitleDelay(Int(sender.value))
        }
    }
}
