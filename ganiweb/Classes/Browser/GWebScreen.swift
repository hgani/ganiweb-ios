import GaniLib

open class GWebScreen: GScreen {
    private let webView = GWebView()
    private let url: URL
    
    public init(url: String) {
        self.url = URL(string: url)!
        
        super.init(container: GScreenContainer(webView: webView))
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("Unsupported operation")
    }
    
//    override open func viewDidLoad() {
//        super.viewDidLoad()
//        
//    }
    
    open override func onRefresh() {
        _ = webView.load(url: url)
    }
}
