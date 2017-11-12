import GaniLib

open class WebScreen: GScreen {
    private let webView = GWebView()
    private let url: URL
    
    public init(url: String) {
        self.url = URL(string: url)!
        
        super.init(container: GScreenContainer(webView: webView))
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("Unsupported operation")
    }
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        
        _ = webView.load(url: url)
    }
}
