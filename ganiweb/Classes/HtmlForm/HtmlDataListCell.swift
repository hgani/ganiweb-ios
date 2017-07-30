//import UIKit
//import Eureka
//import SwiftIconFont
//
//public final class HtmlDataListCell: _FieldCell<String>, CellType {
//    var options: [String]?
//    
//    public required init(style: UITableViewCellStyle, reuseIdentifier: String?) {
//        super.init(style: style, reuseIdentifier: reuseIdentifier)
//    }
//    
//    public required init?(coder aDecoder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//    
//    public override func setup() {
//        super.setup()
//        selectionStyle = .none
//        
//        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(showPicker))
//        let label = UILabel()
//        label.text = "io:android-arrow-dropdown"
//        label.font = label.font.withSize(21)
//        label.textColor = UIColor.from("#CCCCCC")
//        label.parseIcon()
//        label.sizeToFit()
//        // adjust size to enable touch on device
//        label.frame.size = CGSize(width: 30, height: 40)
//        label.textAlignment = .right
//        label.isUserInteractionEnabled = true
//        label.addGestureRecognizer(gestureRecognizer)
//        
//        accessoryView = label
//    }
//    
//    func showPicker() {
//        let controller = HTMLSelectorRowViewController(self) { (controller, value) -> Void in
//            let _ = controller.navigationController?.popViewController(animated: true)
//            self.row.value = value
//            self.row.updateCell()
//        }
//        self.formViewController()?.navigationController?.pushViewController(controller, animated: true)
//        
////        let alert = UIAlertController(title: row.title, message: nil, preferredStyle: .alert)
////        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
////        
////        if let opts = options {
////            for option in opts {
////                alert.addAction(UIAlertAction(title: option, style: .default, handler: { _ in
////                    self.row.value = option
////                    self.formViewController()?.tableView?.reloadData()
////                }))
////            }
////        }
////        
////        self.formViewController()?.present(alert, animated: true, completion: nil)
//    }
//    
//}
