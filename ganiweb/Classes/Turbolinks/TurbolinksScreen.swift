import UIKit
import Turbolinks
import GaniLib

open class TurbolinksScreen: Turbolinks.VisitableViewController {
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
    
//    open func onRefresh() {
//        // To be overridden
//    }
}

extension TurbolinksScreen: ScreenProtocol {
    public var controller: UIViewController {
        get {
            return self
        }
    }
    
    open func onRefresh() {
        // To be overridden
    }
}
