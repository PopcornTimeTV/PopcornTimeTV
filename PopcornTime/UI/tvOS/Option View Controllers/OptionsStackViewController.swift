

import Foundation

class OptionsStackViewController: UIViewController, UITableViewDelegate {
    
    weak var delegate: OptionsViewControllerDelegate? {
        return (parent as? OptionsViewController)?.delegate
    }
    
    @IBOutlet var firstTableView: UITableView!
    @IBOutlet var secondTableView: UITableView!
    @IBOutlet var thirdTableView: UITableView!
    
    var tabBar: UITabBar! {
        return (parent as? OptionsViewController)?.tabBar
    }
    
    var activeTabBarButton: UIView { fatalError("Must be overridden")  }
    
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
        
        let menuGesture = UITapGestureRecognizer(target: self, action: #selector(menuPressed))
        menuGesture.allowedTouchTypes = [NSNumber(value: UITouchType.indirect.rawValue)]
        menuGesture.allowedPressTypes = [NSNumber(value: UIPressType.menu.rawValue)]
        
        view.addGestureRecognizer(menuGesture)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        let betweenTabBarAndTableViewGuide = UIFocusGuide()
        activeTabBarButton.addLayoutGuide(betweenTabBarAndTableViewGuide)
        
        betweenTabBarAndTableViewGuide.topAnchor.constraint(equalTo: activeTabBarButton.bottomAnchor).isActive = true
        betweenTabBarAndTableViewGuide.leadingAnchor.constraint(equalTo: activeTabBarButton.leadingAnchor).isActive = true
        betweenTabBarAndTableViewGuide.trailingAnchor.constraint(equalTo: activeTabBarButton.trailingAnchor).isActive = true
        betweenTabBarAndTableViewGuide.bottomAnchor.constraint(equalTo: firstTableView.topAnchor).isActive = true
        betweenTabBarAndTableViewGuide.preferredFocusedView = firstTableView.cellForRow(at: IndexPath(row: 0, section: 0)) ?? secondTableView.cellForRow(at: IndexPath(row: 0, section: 0))
        
        for tableView: UITableView in [firstTableView, secondTableView, thirdTableView] {
            let betweenTableViewAndTabBarGuide = UIFocusGuide()
            tableView.addLayoutGuide(betweenTableViewAndTabBarGuide)
            
            betweenTableViewAndTabBarGuide.topAnchor.constraint(equalTo: tabBar.bottomAnchor).isActive = true
            betweenTableViewAndTabBarGuide.leadingAnchor.constraint(equalTo: tableView.leadingAnchor).isActive = true
            betweenTableViewAndTabBarGuide.trailingAnchor.constraint(equalTo: tableView.trailingAnchor).isActive = true
            betweenTableViewAndTabBarGuide.bottomAnchor.constraint(equalTo: tableView.topAnchor).isActive = true
            betweenTableViewAndTabBarGuide.preferredFocusedView = tabBar
        }
        
        let lastRightGuide = UIFocusGuide()
        thirdTableView.addLayoutGuide(lastRightGuide)
        
        lastRightGuide.leftAnchor.constraint(equalTo: thirdTableView.rightAnchor).isActive = true
        lastRightGuide.topAnchor.constraint(equalTo: thirdTableView.topAnchor).isActive = true
        lastRightGuide.heightAnchor.constraint(equalToConstant: thirdTableView.contentSize.height).isActive = true
        lastRightGuide.widthAnchor.constraint(equalTo: thirdTableView.widthAnchor).isActive = true
        lastRightGuide.preferredFocusedView = firstTableView
        
        let lastLeftGuide = UIFocusGuide()
        firstTableView.addLayoutGuide(lastLeftGuide)
        
        lastLeftGuide.rightAnchor.constraint(equalTo: firstTableView.leftAnchor).isActive = true
        lastLeftGuide.topAnchor.constraint(equalTo: firstTableView.topAnchor).isActive = true
        lastLeftGuide.heightAnchor.constraint(equalToConstant: firstTableView.contentSize.height).isActive = true
        lastLeftGuide.widthAnchor.constraint(equalTo: firstTableView.widthAnchor).isActive = true
        lastLeftGuide.preferredFocusedView = thirdTableView
        
        let betweenFirstAndSecondGuide = UIFocusGuide()
        firstTableView.addLayoutGuide(betweenFirstAndSecondGuide)
        
        betweenFirstAndSecondGuide.leftAnchor.constraint(equalTo: firstTableView.rightAnchor).isActive = true
        betweenFirstAndSecondGuide.topAnchor.constraint(equalTo: firstTableView.topAnchor).isActive = true
        betweenFirstAndSecondGuide.heightAnchor.constraint(equalToConstant: firstTableView.contentSize.height).isActive = true
        betweenFirstAndSecondGuide.rightAnchor.constraint(equalTo: secondTableView.leftAnchor).isActive = true
        betweenFirstAndSecondGuide.preferredFocusedView = secondTableView
        
        let betweenSecondAndFirstGuide = UIFocusGuide()
        secondTableView.addLayoutGuide(betweenSecondAndFirstGuide)
        
        betweenSecondAndFirstGuide.rightAnchor.constraint(equalTo: secondTableView.leftAnchor).isActive = true
        betweenSecondAndFirstGuide.topAnchor.constraint(equalTo: secondTableView.topAnchor).isActive = true
        betweenSecondAndFirstGuide.heightAnchor.constraint(equalToConstant: secondTableView.contentSize.height).isActive = true
        betweenSecondAndFirstGuide.leftAnchor.constraint(equalTo: firstTableView.rightAnchor).isActive = true
        betweenSecondAndFirstGuide.preferredFocusedView = firstTableView
        
        let betweenThirdAndSecondGuide = UIFocusGuide()
        thirdTableView.addLayoutGuide(betweenThirdAndSecondGuide)
        
        betweenThirdAndSecondGuide.rightAnchor.constraint(equalTo: thirdTableView.leftAnchor).isActive = true
        betweenThirdAndSecondGuide.topAnchor.constraint(equalTo: thirdTableView.topAnchor).isActive = true
        betweenThirdAndSecondGuide.heightAnchor.constraint(equalToConstant: thirdTableView.contentSize.height).isActive = true
        betweenThirdAndSecondGuide.leftAnchor.constraint(equalTo: secondTableView.rightAnchor).isActive = true
        betweenThirdAndSecondGuide.preferredFocusedView = secondTableView
        
        let betweenSecondAndThirdGuide = UIFocusGuide()
        secondTableView.addLayoutGuide(betweenSecondAndThirdGuide)
        
        betweenSecondAndThirdGuide.leftAnchor.constraint(equalTo: secondTableView.rightAnchor).isActive = true
        betweenSecondAndThirdGuide.topAnchor.constraint(equalTo: secondTableView.topAnchor).isActive = true
        betweenSecondAndThirdGuide.heightAnchor.constraint(equalToConstant: secondTableView.contentSize.height).isActive = true
        betweenSecondAndThirdGuide.rightAnchor.constraint(equalTo: thirdTableView.leftAnchor).isActive = true
        betweenSecondAndThirdGuide.preferredFocusedView = thirdTableView
    }
    
    func tableView(_ tableView: UITableView, didUpdateFocusIn context: UITableViewFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        
        tableView.visibleCells.forEach({ $0.textLabel?.textColor = UIColor(red: 169.0/255.0, green: 169.0/255.0, blue: 169.0/255.0, alpha: 0.7) })
        
        if let indexPath = context.nextFocusedIndexPath, let cell = context.nextFocusedView as? UITableViewCell {
            cell.textLabel?.textColor = .white
            tableView.scrollToRow(at: indexPath, at: .none, animated: true)
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
        if let nextFocusedView = context.nextFocusedView, type(of: nextFocusedView) === NSClassFromString("UITabBarButton") {
            return canFocusTabBar
        }
        return true
    }
    
    var viewToFocus: UIView? = nil {
        didSet {
            guard viewToFocus != nil else { return }
            setNeedsFocusUpdate()
            updateFocusIfNeeded()
        }
    }
    
    override var preferredFocusedView: UIView? {
        return viewToFocus != nil ? viewToFocus : super.preferredFocusedView
    }
    
    func menuPressed() {
        if firstTableView.recursiveSubviews.first(where: {$0.isFocused}) != nil || secondTableView.recursiveSubviews.first(where: {$0.isFocused}) != nil || thirdTableView.recursiveSubviews.first(where: {$0.isFocused}) != nil {
            if let item = tabBar.selectedItem, let index = tabBar.items?.index(of: item) {
                viewToFocus = tabBar.subviews.first(where: {$0 is UIScrollView})?.subviews[safe: index]
            }
        } else {
           dismiss(animated: true, completion: nil)
        }
    }
    
}
