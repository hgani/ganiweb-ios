import WebKit
import GaniLib
import Turbolinks

//open class GTurbolinks {
//    static public let instance = GTurbolinks()
//
//////    let url = URL(string: Build.instance.host())
////    fileprivate let webViewProcessPool = WKProcessPool()
////
////    fileprivate lazy var webViewConfiguration: WKWebViewConfiguration = {
////        let conf = WKWebViewConfiguration()
//////        conf.userContentController.add(self, name: "AndersonAnimalClinic")
////        conf.processPool = self.webViewProcessPool
//////        conf.applicationNameForUserAgent = "AndersonAnimalClinic"
////        return conf
////    }()
//
////    lazy var session: Session = {
////        let session = Session(webViewConfiguration: WKWebViewConfiguration())
////        session.delegate = self
////        return session
////    }()
//
////    private var buildConfig: BuildConfig!
////    private(set) var delegate: GHttpDelegate!
//
//    public let session: Session
//
//    init() {
//        self.session = Session(webViewConfiguration: WKWebViewConfiguration())
//        session.delegate = self
//    }
//
////    public func initialize() {
//////        self.buildConfig = buildConfig
//////        self.delegate = delegate
////
////
////    }
//
////    public func host() -> String {
////        assert(buildConfig != nil, "Call GHttp.instance.initialize() in AppDelegate first")
////        return buildConfig.host()
////    }
////
////    public func hostUrl() -> URL {
////        return URL(string: host())!
////    }
////
////    public func clearCookies() {
////        let cstorage = HTTPCookieStorage.shared
////        if let cookies = cstorage.cookies(for: GHttp.instance.hostUrl()) {
////            for cookie in cookies {
////                cstorage.deleteCookie(cookie)
////            }
////        }
////    }
//}

public protocol GTurbolinksSessionDelegate: SessionDelegate {
}

extension GTurbolinksSessionDelegate {
//    public func session(_ session: Session, didProposeVisitToURL URL: URL, withAction action: Action) {
//        // To be overriden
//    }
    
    public func session(_ session: Session, didFailRequestForVisitable visitable: Visitable, withError error: NSError) {
        guard let errorCode = ErrorCode(rawValue: error.code) else { return }
        
        switch errorCode {
        case .httpFailure:
            let statusCode = error.userInfo["statusCode"] as! Int
            _ = GHttp.instance.delegate.processHttpStatus(code: statusCode)
        case .networkFailure:
            GLog.w("Network error: \(error.localizedDescription)")
        }
    }
}
