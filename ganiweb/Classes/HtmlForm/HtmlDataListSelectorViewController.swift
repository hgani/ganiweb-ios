import UIKit
import Eureka

open class HtmlDataListSelectorViewController<OptionsRow: OptionsProviderRow>: SelectorViewController<OptionsRow> where String == OptionsRow.OptionsProviderType.Option {



// T:Equatable,
//public class HtmlDataListSelectorViewController<OptionsRow: OptionsProviderRow>: _SelectorViewController<ListCheckRow<String>, OptionsRow> where String == OptionsRow.OptionsProviderType.Option {
//    override func viewDidLoad() {
//        super.viewDidLoad()
//
////        appendTextRow()
//    }
//
//    private func appendTextRow() {
//        let section = form.allSections.first!
//        let row = TextRow() { row in
//                row.title = "Other (Please specify)"
//            }.cellSetup { (cell, row) in
//                if let options = self.row.dataProvider?.arrayData {
//                    for option in options {
//                        if self.row.value == option {
//                            return
//                        }
//                    }
//
//                    row.value = self.row.value as! String?
//                }
//            }.cellUpdate { (_, row) in
//                let changed = self.row.value != ((row.value ?? "") as! T)
//                if row.value != nil && changed {
//                    self.row.value = (row.value as! T)
//                    self.onDismissCallback?(self)
//                }
//            }
//
//        section <<< row
//    }
}

//class HTMLSelectorRowViewController: UITableViewController {
//    public var dataListCell: HTMLDataListCell?
//    public var onDismissCallback: ((UIViewController, String) -> ())?
//    
//    let cellIdentifier = "OptionCell"
//    
//    override public init(style: UITableViewStyle) {
//        super.init(style: style)
//    }
//    
//    public convenience init(_ cell: HTMLDataListCell, callback: ((UIViewController, String) -> ())?) {
//        self.init(style: .plain)
//        self.dataListCell = cell
//        self.onDismissCallback = callback
//    }
//    
//    required init?(coder aDecoder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//    
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        
//        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellIdentifier)
//    }
//    
//    override func numberOfSections(in tableView: UITableView) -> Int {
//        return 1
//    }
//    
//    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        if let options = dataListCell?.options {
//            return options.count
//        }
//        
//        return 0
//    }
//    
//    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath)
//        
//        cell.textLabel?.text = dataListCell?.options?[indexPath.row]
//        if cell.textLabel?.text == dataListCell?.row.value {
//            cell.accessoryType = .checkmark
//        }
//        
//        return cell
//    }
//    
//    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        for section in 0..<tableView.numberOfSections {
//            for row in 0..<tableView.numberOfRows(inSection: section) {
//                if let cell = tableView.cellForRow(at: IndexPath(row: row, section: section)) {
//                    cell.accessoryType = .none
//                }
//            }
//        }
//        
//        if let cell = tableView.cellForRow(at: indexPath) {
//            cell.accessoryType = .checkmark
//            cell.selectionStyle = .none
//            self.onDismissCallback?(self, (cell.textLabel?.text)!)
//        }
//    }
//}
