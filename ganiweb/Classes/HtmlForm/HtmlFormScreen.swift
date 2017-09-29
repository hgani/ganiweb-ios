
import Eureka
import SVProgressHUD
import GaniLib

open class HtmlFormScreen: GFormScreen {
    public private(set) var htmlForm: HtmlForm!
    public private(set) var section: Section!
    lazy fileprivate var refresher: GRefreshControl = {
        return GRefreshControl().onValueChanged {
            self.onRefresh()
        }
    }()

    open override func viewDidLoad() {
        super.viewDidLoad()
        
        _ = self.leftBarButton(item: GBarButtonItem()
            .title("Cancel")
            .onClick {
            self.launch.confirm("Changes will be discarded. Are you sure?", title: nil, handler: {
                // https://stackoverflow.com/questions/39576314/dealloc-a-viewcontroller-warning
                DispatchQueue.main.async {
                    _ = self.nav.pop()
                }
            })
        })
        
        appendRefreshControl()
        setupForm()
    }
    
    private func setupForm() {
        self.tableView?.contentInset = UIEdgeInsetsMake(-36, 0, -36, 0)  // Eureka-specific requirements
        self.section = Section()
        
        // section.header!.height = {0}
        // section.header = headerForm(title: "HEADER", height: 150)
        
        form += [section]
        
        self.htmlForm = HtmlForm(form: form, onSubmitSucceeded: { result in
            if !self.onSubmitted(result: result) {
                if let message = result["message"].string {
                    SVProgressHUD.showError(withStatus: message)
                }
                else if let message = result["error"].string {  // Devise uses "error" key
                    SVProgressHUD.showError(withStatus: message)
                }
            }
        })
    }
    
    private func appendRefreshControl() {
        tableView?.addSubview(refresher)
        
        // Eureka-specific requirements
        refresher.snp.makeConstraints { (make) -> Void in
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
    
    
    public func loadForm(path: String) {
        htmlForm.load(path, indicator: refresher, onSuccess: {
            // Allow subclass to populate header/footer, i.e. when htmlForm has been rendered.
            // E.g. `if !self.htmlForm.rendered { return }`
            self.section.reload()
            self.onLoaded()
        })
    }
    
    open func onLoaded() {
        // To be overidden
    }
    
    open func onSubmitted(result: Json) -> Bool {
        // To be overidden
        return true
    }
}
