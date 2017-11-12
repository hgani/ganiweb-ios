import GaniLib

open class GWebScreen: GScreen {
    private let webView = GWebView()
    private let url: URL
    private let autoLoad: Bool
    
    public init(url: String, autoLoad: Bool = false) {
        self.url = URL(string: url)!
        self.autoLoad = autoLoad
        
        super.init(container: GScreenContainer(webView: webView))
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("Unsupported operation")
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        
        if autoLoad {
            _ = webView.load(url: url)
        }
    }
    
    open override func onRefresh() {
        webView.reload()
    }
}
