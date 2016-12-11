

import UIKit
import PopcornKit

protocol OptionsViewControllerDelegate: class {
    func didSelectSubtitle(_ subtitle: Subtitle?)
    func didSelectDelay(_ delay: Int)
    func didSelectEncoding(_ encoding: String)
}

class SubtitlesViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    weak var delegate: OptionsViewControllerDelegate?
    
    @IBOutlet var languageTableView: UITableView!
    @IBOutlet var delayTableView: UITableView!
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
    let delays: [Int] = {
        var delays = [Int]()
        for delay in -5...5 {
            delays.append(delay)
        }
        return delays
    }()
    
    var currentSubtitle: Subtitle?
    var currentDelay = 0
    var currentEncoding = SubtitleSettings().encoding {
        didSet {
            let subtitle = SubtitleSettings()
            subtitle.encoding = currentEncoding
            subtitle.save()
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        for tableView in [languageTableView, delayTableView, encodingTableView] {
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
        betweenFirstAndSecondGuide.rightAnchor.constraint(equalTo: delayTableView.leftAnchor).isActive = true
        betweenFirstAndSecondGuide.preferredFocusedView = delayTableView
        
        let betweenSecondAndFirstGuide = UIFocusGuide()
        delayTableView.addLayoutGuide(betweenSecondAndFirstGuide)
        
        betweenSecondAndFirstGuide.rightAnchor.constraint(equalTo: delayTableView.leftAnchor).isActive = true
        betweenSecondAndFirstGuide.topAnchor.constraint(equalTo: delayTableView.topAnchor).isActive = true
        betweenSecondAndFirstGuide.heightAnchor.constraint(equalToConstant: delayTableView.contentSize.height).isActive = true
        betweenSecondAndFirstGuide.leftAnchor.constraint(equalTo: languageTableView.rightAnchor).isActive = true
        betweenSecondAndFirstGuide.preferredFocusedView = languageTableView
        
        let betweenThirdAndSecondGuide = UIFocusGuide()
        encodingTableView.addLayoutGuide(betweenThirdAndSecondGuide)
        
        betweenThirdAndSecondGuide.rightAnchor.constraint(equalTo: encodingTableView.leftAnchor).isActive = true
        betweenThirdAndSecondGuide.topAnchor.constraint(equalTo: encodingTableView.topAnchor).isActive = true
        betweenThirdAndSecondGuide.heightAnchor.constraint(equalToConstant: encodingTableView.contentSize.height).isActive = true
        betweenThirdAndSecondGuide.leftAnchor.constraint(equalTo: delayTableView.rightAnchor).isActive = true
        betweenThirdAndSecondGuide.preferredFocusedView = delayTableView
        
        let betweenSecondAndThirdGuide = UIFocusGuide()
        delayTableView.addLayoutGuide(betweenSecondAndThirdGuide)
        
        betweenSecondAndThirdGuide.leftAnchor.constraint(equalTo: delayTableView.rightAnchor).isActive = true
        betweenSecondAndThirdGuide.topAnchor.constraint(equalTo: delayTableView.topAnchor).isActive = true
        betweenSecondAndThirdGuide.heightAnchor.constraint(equalToConstant: delayTableView.contentSize.height).isActive = true
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
        case delayTableView:
            let delay = delays[indexPath.row]
            cell.textLabel?.text = (delay > 0 ? "+" : "") + "\(delay).0"
            cell.accessoryType = currentDelay == delay ? .checkmark : .none
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
        case delayTableView:
            return "Delay"
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
        case delayTableView:
            return delays.count
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
        case delayTableView:
            currentDelay = delays[indexPath.row]
            delegate?.didSelectDelay(currentDelay)
        case encodingTableView:
            currentEncoding = Array(encodings.values)[indexPath.row]
            delegate?.didSelectEncoding(currentEncoding)
        default:
            break
        }
        tableView.reloadData()
    }
}
