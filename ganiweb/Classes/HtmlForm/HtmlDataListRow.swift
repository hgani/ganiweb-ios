import UIKit
import Eureka

open class _HtmlDataListRow<Cell: CellType>: SelectorRow<Cell> where Cell: BaseCell {
    //typealias PresenterRow = HtmlDataListSelectorViewController<PushRow<String>>
    public typealias PresenterRow = HtmlDataListSelectorViewController<PushRow<String>>

    public required init(tag: String?) {
        super.init(tag: tag)
//        PresentationMode.show()
//        presentationMode = .show(controllerProvider: ControllerProvider.callback { return HtmlDataListSelectorViewController<PushRow<String>>(){ _ in } }, onDismiss: { vc in
//            let _ = vc.navigationController?.popViewController(animated: true) })
        
        
        presentationMode = .show(controllerProvider: ControllerProvider.callback { return SelectorViewController() }, onDismiss: { vc in
            let _ = vc.navigationController?.popViewController(animated: true) })
    }
}

public final class HtmlDataListRow<T: Equatable>: _HtmlDataListRow<PushSelectorCell<T>>, RowType {
//    typealias PresenterRow = HtmlDataListSelectorViewController

    var html: String?
    
    public required init(tag: String?) {
        super.init(tag: tag)
    }
}


//open class TestRow<Cell: CellType>: SelectorRow<Cell>, RowType where Cell: BaseCell {
//    //typealias PresenterRow = HtmlDataListSelectorViewController<PushRow<String>>
////    public typealias PresenterRow = HtmlDataListSelectorViewController<PushRow<String>>
//    
//    public required init(tag: String?) {
//        super.init(tag: tag)
//        //        PresentationMode.show()
//        presentationMode = .show(controllerProvider: ControllerProvider.callback { return SelectorViewController() }, onDismiss: { vc in
//            let _ = vc.navigationController?.popViewController(animated: true) })
//    }
//}

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
