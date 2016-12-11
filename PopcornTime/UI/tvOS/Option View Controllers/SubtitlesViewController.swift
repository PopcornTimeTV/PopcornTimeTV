

import UIKit
import PopcornKit

protocol OptionsViewControllerDelegate: class {
    func didSelectSubtitle(_ subtitle: Subtitle?)
    func didSelectSize(_ size: Float)
    func didSelectEncoding(_ encoding: String)
}

class SubtitlesViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    weak var delegate: OptionsViewControllerDelegate?
    
    @IBOutlet var languageTableView: UITableView!
    @IBOutlet var sizeTableView: UITableView!
    @IBOutlet var encodingTableView: UITableView!
    
    var subtitles = [Subtitle]()
    let encodings: [String: String] = {
        guard let path = Bundle.main.path(forResource: "EncodingTypes", ofType: "plist"),
            let labels = NSDictionary(contentsOfFile: path) as? [String: [String]],
            let titles = labels["Titles"],
            let values = labels["Values"],
            titles.count == values.count else { return [String: String]() }
        var dict = [String: String]()
        for (index, key) in titles.enumerated() {
            dict[key] = values[index]
        }
        return dict
    }()
    let sizes: [String: Float] = ["Small (46pts)" : 20.0, "Medium (56pts)" : 16.0, "Medium Large (66pts)" : 12.0, "Large (96pts)" : 6.0]
    
    var currentSubtitle: Subtitle?
    var currentEncoding = SubtitleSettings().encoding {
        didSet {
            let subtitle = SubtitleSettings()
            subtitle.encoding = currentEncoding
            subtitle.save()
        }
    }
    var currentSize = SubtitleSettings().size {
        didSet {
            let subtitle = SubtitleSettings()
            subtitle.size = currentSize
            subtitle.save()
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        for tableView in [languageTableView, sizeTableView, encodingTableView] {
            tableView?.mask = nil
            tableView?.clipsToBounds = true
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        let lastRightGuide = UIFocusGuide()
        encodingTableView.addLayoutGuide(lastRightGuide)
        
        lastRightGuide.leftAnchor.constraint(equalTo: encodingTableView.rightAnchor).isActive = true
        lastRightGuide.topAnchor.constraint(equalTo: encodingTableView.topAnchor).isActive = true
        lastRightGuide.heightAnchor.constraint(equalToConstant: encodingTableView.contentSize.height).isActive = true
        lastRightGuide.widthAnchor.constraint(equalTo: encodingTableView.widthAnchor).isActive = true
        lastRightGuide.preferredFocusedView = languageTableView
        
        let lastLeftGuide = UIFocusGuide()
        languageTableView.addLayoutGuide(lastLeftGuide)
        
        lastLeftGuide.rightAnchor.constraint(equalTo: languageTableView.leftAnchor).isActive = true
        lastLeftGuide.topAnchor.constraint(equalTo: languageTableView.topAnchor).isActive = true
        lastLeftGuide.heightAnchor.constraint(equalToConstant: languageTableView.contentSize.height).isActive = true
        lastLeftGuide.widthAnchor.constraint(equalTo: languageTableView.widthAnchor).isActive = true
        lastLeftGuide.preferredFocusedView = encodingTableView
        
        let betweenFirstAndSecondGuide = UIFocusGuide()
        languageTableView.addLayoutGuide(betweenFirstAndSecondGuide)
        
        betweenFirstAndSecondGuide.leftAnchor.constraint(equalTo: languageTableView.rightAnchor).isActive = true
        betweenFirstAndSecondGuide.topAnchor.constraint(equalTo: languageTableView.topAnchor).isActive = true
        betweenFirstAndSecondGuide.heightAnchor.constraint(equalToConstant: languageTableView.contentSize.height).isActive = true
        betweenFirstAndSecondGuide.rightAnchor.constraint(equalTo: sizeTableView.leftAnchor).isActive = true
        betweenFirstAndSecondGuide.preferredFocusedView = sizeTableView
        
        let betweenSecondAndFirstGuide = UIFocusGuide()
        sizeTableView.addLayoutGuide(betweenSecondAndFirstGuide)
        
        betweenSecondAndFirstGuide.rightAnchor.constraint(equalTo: sizeTableView.leftAnchor).isActive = true
        betweenSecondAndFirstGuide.topAnchor.constraint(equalTo: sizeTableView.topAnchor).isActive = true
        betweenSecondAndFirstGuide.heightAnchor.constraint(equalToConstant: sizeTableView.contentSize.height).isActive = true
        betweenSecondAndFirstGuide.leftAnchor.constraint(equalTo: languageTableView.rightAnchor).isActive = true
        betweenSecondAndFirstGuide.preferredFocusedView = languageTableView
        
        let betweenThirdAndSecondGuide = UIFocusGuide()
        encodingTableView.addLayoutGuide(betweenThirdAndSecondGuide)
        
        betweenThirdAndSecondGuide.rightAnchor.constraint(equalTo: encodingTableView.leftAnchor).isActive = true
        betweenThirdAndSecondGuide.topAnchor.constraint(equalTo: encodingTableView.topAnchor).isActive = true
        betweenThirdAndSecondGuide.heightAnchor.constraint(equalToConstant: encodingTableView.contentSize.height).isActive = true
        betweenThirdAndSecondGuide.leftAnchor.constraint(equalTo: sizeTableView.rightAnchor).isActive = true
        betweenThirdAndSecondGuide.preferredFocusedView = sizeTableView
        
        let betweenSecondAndThirdGuide = UIFocusGuide()
        sizeTableView.addLayoutGuide(betweenSecondAndThirdGuide)
        
        betweenSecondAndThirdGuide.leftAnchor.constraint(equalTo: sizeTableView.rightAnchor).isActive = true
        betweenSecondAndThirdGuide.topAnchor.constraint(equalTo: sizeTableView.topAnchor).isActive = true
        betweenSecondAndThirdGuide.heightAnchor.constraint(equalToConstant: sizeTableView.contentSize.height).isActive = true
        betweenSecondAndThirdGuide.rightAnchor.constraint(equalTo: encodingTableView.leftAnchor).isActive = true
        betweenSecondAndThirdGuide.preferredFocusedView = encodingTableView
    }

    // MARK: Table view data source
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        switch tableView {
        case languageTableView:
            cell.textLabel?.text = subtitles[indexPath.row].language
            cell.accessoryType = currentSubtitle == subtitles[indexPath.row] ? .checkmark : .none
        case sizeTableView:
            cell.textLabel?.text = Array(sizes.keys)[indexPath.row]
            cell.accessoryType = currentSize == Array(sizes.values)[indexPath.row] ? .checkmark : .none
        case encodingTableView:
            cell.textLabel?.text = Array(encodings.keys)[indexPath.row]
            cell.accessoryType = currentEncoding == Array(encodings.values)[indexPath.row] ? .checkmark : .none
        default:
            break
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch tableView {
        case languageTableView:
            return "Language"
        case sizeTableView:
            return "Size"
        case encodingTableView:
            return "Encoding"
        default:
            return nil
        }
    }
    
    // MARK: Table view delegate
    
    func numberOfSections(in tableView: UITableView) -> Int {
        tableView.backgroundView = nil
        if tableView == languageTableView && subtitles.isEmpty {
            let label = UILabel(frame: CGRect(origin: .zero, size: CGSize(width: 200.0, height: 20)))
            tableView.backgroundView = label
            label.text = "No subtitles available."
            label.textColor = UIColor(white: 1.0, alpha: 0.5)
            label.textAlignment = .center
            label.font = UIFont.systemFont(ofSize: 35.0, weight: UIFontWeightMedium)
            label.center = tableView.center
            label.sizeToFit()
        }
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch tableView {
        case languageTableView:
            return subtitles.count
        case sizeTableView:
            return sizes.count
        case encodingTableView:
            return encodings.count
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, didUpdateFocusIn context: UITableViewFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        if let indexPath = context.nextFocusedIndexPath, let cell = tableView.cellForRow(at: indexPath) {
            cell.textLabel?.textColor = UIColor.white
            tableView.scrollToRow(at: tableView.indexPath(for: cell)!, at: .none, animated: true)
        }
        if let indexPath = context.previouslyFocusedIndexPath, let cell = tableView.cellForRow(at: indexPath) {
            cell.textLabel?.textColor = UIColor.lightGray
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        guard let header = view as? UITableViewHeaderFooterView else { return }
        header.textLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        header.textLabel?.alpha = 0.45
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch tableView {
        case languageTableView:
            if currentSubtitle == subtitles[indexPath.row] { // If row was already selected, user wants to remove the selection.
                currentSubtitle = nil
            } else {
                currentSubtitle = subtitles[indexPath.row]
            }
            delegate?.didSelectSubtitle(currentSubtitle)
        case sizeTableView:
            currentSize = Array(sizes.values)[indexPath.row]
            delegate?.didSelectSize(currentSize)
        case encodingTableView:
            currentEncoding = Array(encodings.values)[indexPath.row]
            delegate?.didSelectEncoding(currentEncoding)
        default:
            break
        }
        tableView.reloadData()
    }
}
