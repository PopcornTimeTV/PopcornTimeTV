

import UIKit

protocol GenresDelegate: class {
    func populateGenres(_ array: inout [String])
    func didSelectGenre(at index: Int)
}


class GenresTableViewController: UITableViewController, NSDiscardableContent {
    
    weak var delegate: GenresDelegate?
    var genres = [String]()
    var selectedRow: Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        delegate?.populateGenres(&genres)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return genres.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = genres[indexPath.row]
        if selectedRow == indexPath.row {
            cell.accessoryType = .checkmark
            cell.textLabel?.textColor = .app
        } else {
            cell.accessoryType = .none
            cell.textLabel?.textColor = .white
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedRow = indexPath.row
        delegate?.didSelectGenre(at: indexPath.row)
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func dismiss() {
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: - NSDiscardableContent
    
    func beginContentAccess() -> Bool {
        return true
    }
    func endContentAccess() {}
    func discardContentIfPossible() {}
    func isContentDiscarded() -> Bool {
        return false
    }
}
