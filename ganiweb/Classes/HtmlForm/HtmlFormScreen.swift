import Eureka
import GaniLib

open class HtmlFormScreen: GFormScreen {
    public private(set) var htmlForm: HtmlForm!
    private var section: Section!
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
        //self.tableView?.contentInset = UIEdgeInsetsMake(-16, 0, -16, 0)  // Eureka-specific requirements
        self.section = Section()
        
        form += [section]
        
        setupHeader(height: 0) { _ in
            // This is just to remove the gap at the top
        }
        
        self.htmlForm = HtmlForm(form: form, onSubmitSucceeded: { result in
            if !self.onSubmitted(result: result) {
                if let message = result["message"].string {
                    self.indicator.show(error: message)
                }
                else if let message = result["error"].string {  // Devise uses "error" key
                    self.indicator.show(error: message)
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
    
    private func setupHeaderFooter(height: Int, populate: @escaping (GHeaderFooterView) -> Void) -> HeaderFooterView<GHeaderFooterView> {
        var headerFooter = HeaderFooterView<GHeaderFooterView>(.class)
        headerFooter.height = { self.htmlForm.rendered ? CGFloat(height) : 0 }
        headerFooter.onSetupView = { view, section in
            view.paddings(t: 15, l: 20, b: 15, r: 20).clearViews()
            populate(view)
        }
        return headerFooter
    }
    
    public func setupHeader(height: Int, populate: @escaping (GHeaderFooterView) -> Void) {
        section.header = setupHeaderFooter(height: height, populate: populate)
    }
    
    public func setupFooter(height: Int, populate: @escaping (GHeaderFooterView) -> Void) {
        section.footer = setupHeaderFooter(height: height, populate: populate)
    }
    
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
