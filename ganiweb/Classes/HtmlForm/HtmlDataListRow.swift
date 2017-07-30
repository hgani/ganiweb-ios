import UIKit
import Eureka

open class _HtmlDataListRow<Cell: CellType>: SelectorRow<Cell, HtmlDataListSelectorViewController<Cell.Value>> where Cell: BaseCell {
    public required init(tag: String?) {
        super.init(tag: tag)
        presentationMode = .show(controllerProvider: ControllerProvider.callback { return HtmlDataListSelectorViewController<Cell.Value>(){ _ in } }, onDismiss: { vc in
            let _ = vc.navigationController?.popViewController(animated: true) })
    }
}

public final class HtmlDataListRow<T: Equatable>: _HtmlDataListRow<PushSelectorCell<T>>, RowType {
    var html: String?
    
    public required init(tag: String?) {
        super.init(tag: tag)
    }
}

//public final class HTMLDataListRow: Row<HTMLDataListCell>, RowType {
//    var html: String?
//    var options: [String]? {
//        didSet {
//            if let opt = options {
//                cell.options = opt
//            }
//        }
//    }
//
//    public required init(tag: String?) {
//        super.init(tag: tag)
//    }
//}
