import UIKit
import Turbolinks
import GaniLib

open class GTurbolinksScreen: Turbolinks.VisitableViewController {
    public var helper : ScreenHelper!
    public var nav : NavHelper!
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        
        self.helper = ScreenHelper(self)
        self.nav = NavHelper(self)

//        helper.setupLeftMenuButton()
    }
    
    override open func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        helper.viewWillAppear()
    }
    
    public func leftMenu(controller: UITableViewController) -> Self {
        helper.leftMenu(controller: controller)
        return self
    }
    
    public func rightBarButton(item: GBarButtonItem) -> Self {
        self.navigationItem.rightBarButtonItem = item
        return self
    }
    
    // Don't declare this in an extension or else we'll get compile error
    // See https://stackoverflow.com/questions/44616409/declarations-in-extensions-cannot-override-yet-error-in-swift-4
    open func onRefresh() {
        // To be overridden
    }
}

extension GTurbolinksScreen: ScreenProtocol {
    public var controller: UIViewController {
        get {
            return self
        }
    }
}
