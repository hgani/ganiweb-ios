
import Eureka
import SwiftyJSON
import SVProgressHUD

import GaniLib

open class HtmlFormScreen: GFormScreen {
    public private(set) var htmlForm: HtmlForm!
    private var refreshControl: UIRefreshControl!
    public var formURL: URL!
    public private(set) var section: Section!
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        
        appendRefreshControl()
        setupForm()
    }
    
    private func setupForm() {
        self.tableView?.contentInset = UIEdgeInsetsMake(-36, 0, -36, 0)
        self.section = Section()
        
        // section.header!.height = {0}
        // section.header = headerForm(title: "HEADER", height: 150)
        
        form += [section]
    }
    
    private func appendRefreshControl() {
        self.refreshControl = UIRefreshControl()
        refreshControl.addTarget(self,
                                 action: #selector(loadForm),
                                 for: UIControlEvents.valueChanged)
        self.tableView?.addSubview(refreshControl)
        
        refreshControl.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(4)
            make.centerX.equalTo(tableView!)
        }
    }
    
//    
//    func headerForm(title: String?, height: CGFloat) -> HeaderFooterView<UIView> {
//        var header = HeaderFooterView<UIView>(.class)
//        header.height = {height}
//        header.onSetupView = { view, section in
//            view.backgroundColor = .white
//            
//            let label = UILabel()
//            label.text = title
//            label.numberOfLines = 0
//            label.textAlignment = .center
//            
//            view.addSubview(label)
//            
//            label.snp.makeConstraints { (make) -> Void in
//                make.width.equalTo(view).offset(-20)
//                make.height.equalTo(view)
//                make.left.equalTo(10)
//                make.right.equalTo(10)
//            }
//        }
//        
//        return header
//    }
    
    
    //@objc public func loadForm() {
    @objc public func loadForm() {
        self.htmlForm = HtmlForm(formURL: formURL.absoluteString, form: form, onSubmitSucceeded: { result in
            if !self.onSubmitted(result: result) {
                if let message = result["message"].string {
                    SVProgressHUD.showError(withStatus: message)
                }
                else if let message = result["error"].string {  // Devise uses "error" key
                    SVProgressHUD.showError(withStatus: message)
                }
            }
        })
        htmlForm.load(onSuccess: {
            self.onLoaded()
        })
    }
    
    open func onLoaded() {
        // To be overidden
    }
    
    open func onSubmitted(result: JSON) -> Bool {
        // To be overidden
        return true
    }
}
