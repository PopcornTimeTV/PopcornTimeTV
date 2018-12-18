

import Foundation

class OptionsStackViewController: UIViewController, UITableViewDelegate {
    
    weak var delegate: OptionsViewControllerDelegate? {
        return (parent as? OptionsViewController)?.delegate
    }
    
    @IBOutlet var firstTableView: UITableView!
    @IBOutlet var secondTableView: UITableView!
    @IBOutlet var thirdTableView: UITableView!
    
    let topGuide = UIFocusGuide()
    let leftGuide = UIFocusGuide()
    let rightGuide = UIFocusGuide()
    let bottomGuide = UIFocusGuide()
    let firstSecondGuide = UIFocusGuide()
    let secondThirdGuide = UIFocusGuide()
    
    var tabBar: UITabBar! {
        return (parent as? OptionsViewController)?.tabBar
    }
    
    /// Stop the tab bar from being focused.
    var canFocusTabBar = true
    
    private var workItem: DispatchWorkItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        for tableView in [firstTableView, secondTableView, thirdTableView] {
            tableView?.mask = nil
            tableView?.clipsToBounds = true
            tableView?.contentInset.top = -10.0
        }
        
        view.addLayoutGuide(firstSecondGuide)
        view.addLayoutGuide(secondThirdGuide)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        [firstTableView, secondTableView, thirdTableView].forEach {
            $0?.reloadData()
        }
        
        parent?.view.layoutGuides.forEach({
            $0.isKind(of: UIFocusGuide.self) ? $0.owningView?.removeLayoutGuide($0) : ()
        })
        
        [topGuide, leftGuide, rightGuide, bottomGuide].forEach { (guide) in
            self.parent?.view.addLayoutGuide(guide)
        }
        
        topGuide.topAnchor.constraint(equalTo: tabBar.bottomAnchor).isActive = true
        topGuide.leftAnchor.constraint(equalTo: parent!.view.leftAnchor).isActive = true
        topGuide.rightAnchor.constraint(equalTo: parent!.view.rightAnchor).isActive = true
        topGuide.bottomAnchor.constraint(equalTo: firstTableView.topAnchor).isActive = true
        
        topGuide.preferredFocusEnvironments = [firstTableView, secondTableView, thirdTableView]
        
        leftGuide.topAnchor.constraint(equalTo: firstTableView.topAnchor).isActive = true
        leftGuide.leftAnchor.constraint(equalTo: parent!.view.leftAnchor).isActive = true
        leftGuide.rightAnchor.constraint(equalTo: firstTableView.leftAnchor).isActive = true
        leftGuide.bottomAnchor.constraint(equalTo: parent!.view.bottomAnchor).isActive = true
        
        leftGuide.preferredFocusEnvironments = [thirdTableView, secondTableView, firstTableView]
        
        rightGuide.topAnchor.constraint(equalTo: thirdTableView.topAnchor).isActive = true
        rightGuide.leftAnchor.constraint(equalTo: thirdTableView.rightAnchor).isActive = true
        rightGuide.rightAnchor.constraint(equalTo: parent!.view.rightAnchor).isActive = true
        rightGuide.bottomAnchor.constraint(equalTo: parent!.view.bottomAnchor).isActive = true
        
        rightGuide.preferredFocusEnvironments = [firstTableView, secondTableView, thirdTableView]
        
        bottomGuide.topAnchor.constraint(equalTo: firstTableView.bottomAnchor).isActive = true
        bottomGuide.leftAnchor.constraint(equalTo: parent!.view.leftAnchor).isActive = true
        bottomGuide.rightAnchor.constraint(equalTo: parent!.view.rightAnchor).isActive = true
        bottomGuide.bottomAnchor.constraint(equalTo: parent!.view.bottomAnchor).isActive = true
        
        bottomGuide.preferredFocusEnvironments = [] // Keep focus on the active table view.
        
        firstSecondGuide.topAnchor.constraint(equalTo: firstTableView.topAnchor).isActive = true
        firstSecondGuide.leftAnchor.constraint(equalTo: firstTableView.rightAnchor).isActive = true
        firstSecondGuide.rightAnchor.constraint(equalTo: secondTableView.leftAnchor).isActive = true
        firstSecondGuide.bottomAnchor.constraint(equalTo: parent!.view.bottomAnchor).isActive = true
        
        firstSecondGuide.preferredFocusEnvironments = [secondTableView]
        
        secondThirdGuide.topAnchor.constraint(equalTo: thirdTableView.topAnchor).isActive = true
        secondThirdGuide.leftAnchor.constraint(equalTo: secondTableView.rightAnchor).isActive = true
        secondThirdGuide.rightAnchor.constraint(equalTo: thirdTableView.leftAnchor).isActive = true
        secondThirdGuide.bottomAnchor.constraint(equalTo: parent!.view.bottomAnchor).isActive = true
        
        secondThirdGuide.preferredFocusEnvironments = [secondTableView]
    }
    
    func tableView(_ tableView: UITableView, didUpdateFocusIn context: UITableViewFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        
        tableView.visibleCells.forEach({ $0.textLabel?.textColor = UIColor(white: 1.0, alpha: 0.5) })
        
        if let previous = context.previouslyFocusedView, type(of: previous) == NSClassFromString("UITabBarButton")  {
            topGuide.preferredFocusEnvironments = [tabBar]
        } else if let next = context.nextFocusedView, type(of: next) == NSClassFromString("UITabBarButton") {
            topGuide.preferredFocusEnvironments = [firstTableView, secondTableView, thirdTableView]
        }
        
        if let indexPath = context.nextFocusedIndexPath, let cell = context.nextFocusedView as? UITableViewCell {
            cell.textLabel?.textColor = .white
            tableView.scrollToRow(at: indexPath, at: .none, animated: true)
            
            switch cell.tableView! {
            case firstTableView:
                firstSecondGuide.preferredFocusEnvironments = [secondTableView]
            case secondTableView:
                firstSecondGuide.preferredFocusEnvironments = [firstTableView]
                secondThirdGuide.preferredFocusEnvironments = [thirdTableView]
            case thirdTableView:
                secondThirdGuide.preferredFocusEnvironments = [secondTableView]
            default:
                break
            }
        }
        
        if let indexPath = context.previouslyFocusedIndexPath {
            canFocusTabBar = indexPath.row != 0 ? false : canFocusTabBar
        }
        
        workItem?.cancel()
        
        workItem = DispatchWorkItem() {
            self.canFocusTabBar = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: workItem)
    }
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        guard let header = view as? UITableViewHeaderFooterView else { return }
        header.textLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        header.textLabel?.alpha = 0.45
    }
    
    override func shouldUpdateFocus(in context: UIFocusUpdateContext) -> Bool {
        if let nextFocusedView = context.nextFocusedView, type(of: nextFocusedView) == NSClassFromString("UITabBarButton") {
            return canFocusTabBar
        }
        return true
    }
}
