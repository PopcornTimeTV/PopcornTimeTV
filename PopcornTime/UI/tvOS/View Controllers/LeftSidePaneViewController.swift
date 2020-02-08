
import TVUIKit
import Foundation
import class PopcornKit.MovieManager
import class PopcornKit.ShowManager
import class PopcornKit.NetworkManager

class LeftSidePaneViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tableViewSelectionTab:UISegmentedControl?
    @IBOutlet weak var tableView:UITableView?
    var selectedIndex: IndexPath?
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        tableView?.selectRow(at: selectedIndex, animated: false, scrollPosition: .middle)
    }
    
    @IBAction func selectedDifferentFilter(_ sender: Any){
        tableView?.reloadData()
        tableView?.layoutIfNeeded()
        tableView?.selectRow(at: selectedIndex, animated: false, scrollPosition: .middle)
    }
    
    @IBAction func showExternalTorrentWindow(_ sender: Any) {
        let storyboard = UIStoryboard.main
        let externalTorrentViewController = storyboard.instantiateViewController(withIdentifier: "LoadExternalTorrentViewController")
        present(externalTorrentViewController, animated: true)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0{
            return tableViewSelectionTab?.selectedSegmentIndex == 0 ? MovieManager.Filters.array.count : NetworkManager.Genres.array.count
        }
        return 0
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: "sideWindowTableCell")
        guard let mainController = self.parent as? MediaViewController
        else{
            return UITableViewCell()
        }

        if tableViewSelectionTab?.selectedSegmentIndex == 0 {
            if mainController is MoviesViewController{
                for (index,element) in MovieManager.Filters.array.enumerated(){
                    if indexPath.row == index{
                        cell.textLabel?.text = element.string
                        if (mainController as! MoviesViewController).currentFilter == element{
                            selectedIndex = indexPath
                        }
                        break
                    }
                }
            }else if mainController is ShowsViewController{
                for (index,element) in ShowManager.Filters.array.enumerated(){
                    if indexPath.row == index{
                        cell.textLabel?.text = element.string
                        if (mainController as! ShowsViewController).currentFilter == element{
                            selectedIndex = indexPath
                        }
                        break
                    }
                }
            }
            
        }else{
            for (index,element) in NetworkManager.Genres.array.enumerated(){
                if indexPath.row == index{
                    cell.textLabel?.text = element.string
                    if mainController.currentGenre == element{
                        selectedIndex = indexPath
                    }
                    break
                }
            }
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.selectedIndex = IndexPath(indexes: indexPath)//copy(indexPath) as! IndexPath
        guard let mainController = (self.parent as? MediaViewController)
        else {
            return
        }
        if tableViewSelectionTab?.selectedSegmentIndex == 0 {
            if mainController is MoviesViewController{
                (mainController as! MoviesViewController).currentFilter = MovieManager.Filters.array.first(where: {$0.string == tableView.cellForRow(at: indexPath)?.textLabel?.text!}) ?? .trending
            }else if mainController is ShowsViewController{
                (mainController as! ShowsViewController).currentFilter = ShowManager.Filters.array.first(where: {$0.string == tableView.cellForRow(at: indexPath)?.textLabel?.text!}) ?? .trending
            }
            
        }else{
            mainController.currentGenre = NetworkManager.Genres.array.first(where: {$0.string == tableView.cellForRow(at: indexPath)?.textLabel?.text!}) ?? .all
        }
    }
    
    override func shouldUpdateFocus(in context: UIFocusUpdateContext) -> Bool {
        super.shouldUpdateFocus(in: context)
        if self == context.nextFocusedView?.parent{
            guard let mainController = self.parent as? MainViewController
            else {
                return true
            }
            if mainController.sidePanelConstraint?.constant == 0{
                UIView.animate(withDuration: 0.4) {
                    mainController.sidePanelConstraint?.constant += self.view.frame.size.width
                    mainController.view.layoutIfNeeded()
                    
                }
            }
            return true

        }else if context.focusHeading == .right{
            guard let mainController = self.parent as? MainViewController
            else {
                return true
            }
            UIView.animate(withDuration: 0.4) {
                mainController.sidePanelConstraint?.constant = 0
                mainController.view.layoutIfNeeded()
            }
            return true
        }
        return false
    }
}
