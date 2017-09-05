import GaniLib

import Eureka
//import ImageRow
import Alamofire
import Kanna
import SVProgressHUD
import SwiftyJSON

public class HtmlForm {
    let formURL: String
    let form: Form
    
    var section: Section!
    private var formAction: String!
    var document: HTMLDocument!
//    var delegate: HTMLFormOnSubmitDelegate?
    
    private let onSubmitSucceeded: ((JSON)->Void)
    
    public private(set) var rendered = false
    
    init(formURL: String, form: Form, onSubmitSucceeded: @escaping ((JSON)->Void)) {
        self.formURL = formURL
        self.form = form
        self.onSubmitSucceeded = onSubmitSucceeded
    }
    
    static func preload(paths: [String]) {
        DispatchQueue.global(qos: .background).async {
            for path in paths {
                _ = Alamofire.request(GHttp.instance.host() + "/\(path)")
            }
        }
    }
    
    static func saveToken(_ json: JSON) {
        let userDefaults = UserDefaults.standard
        for key in ["jwt_token", "csrf_token"] {
            userDefaults.set(json[key].stringValue, forKey: key)
        }
    }
    
    static func getJWTToken() -> String {
        let userDefaults = UserDefaults.standard
        
        if let token = userDefaults.value(forKey: "jwt_token") as? String {
            return token
        }
        
        return ""
    }
    
    static func getCSRFToken() -> String {
        let userDefaults = UserDefaults.standard
        
        if let token = userDefaults.value(forKey: "csrf_token") as? String {
            return token
        }
        
        return ""
    }
    
    static func saveCookie() {
        let url = URL(string: GHttp.instance.host())
        let userDefaults = UserDefaults.standard
        let cookieStorage = HTTPCookieStorage.shared
        var dictionary = [String: AnyObject]()

        for cookie in cookieStorage.cookies(for: url!)! {
            dictionary[cookie.name] = cookie.properties as AnyObject?
        }

        userDefaults.set(dictionary, forKey: GHttp.instance.host())
    }
    
    static func syncCookie() {
        let userDefaults = UserDefaults.standard
        let cookieStorage = HTTPCookieStorage.shared
        
        if let dictionary = userDefaults.dictionary(forKey: GHttp.instance.host()) {
            for (_, properties) in dictionary {
                if let cookie = HTTPCookie(properties: properties as! [HTTPCookiePropertyKey : Any]) {
                    cookieStorage.setCookie(cookie)
                }
            }
        }
    }
    
    static func getCookie() -> String {
        let url = URL(string: GHttp.instance.host())
        if let cookies = HTTPCookieStorage.shared.cookies(for: url!) {
            let cookieString = cookies.map({ (cookie) -> String in
                return "\(cookie.name)=\(cookie.value)"
            }).joined(separator: ";")
            
            return cookieString
        }
        
        return ""
    }
    
    public func headers() -> HTTPHeaders {
        let csrfToken = document.at_css("meta[name='csrf-token']")?["content"]
        return [
            "Cookie": HtmlForm.getCookie(),
            "X-CSRF-Token": csrfToken!,
        ]
    }
    
    public func load(onSuccess: (()->Void)? = nil) {
        SVProgressHUD.show()
        
        let urlRequest = URLRequest(url: URL(string: formURL)!)
        if let cachedResponse = URLCache.shared.cachedResponse(for: urlRequest) {
            let htmlString = String(data: cachedResponse.data, encoding: .utf8)
            let docCached = Kanna.HTML(html: htmlString!, encoding: .utf8)
            processDocument(doc: docCached!)
        }
        
        NSLog("URL: \(formURL)")
        
        Alamofire.request(formURL).responseString { response in
//            self.delegate?.onComplete()
            
            if self.responseStatusSuccess(response: response)
                && response.result.isSuccess {
                
                SVProgressHUD.dismiss()
                
                if let html = response.result.value {
                    if let doc = Kanna.HTML(html: html, encoding: .utf8) {
                        self.processDocument(doc: doc)
                        onSuccess?()
                    }
                }
            }
            else {
                if (response.error != nil) {
                    SVProgressHUD.showError(withStatus: response.error!.localizedDescription)
                }
                else {
                    if (response.response!.statusCode == 500) {
                        SVProgressHUD.showError(withStatus: "Server encountered an error. Please try again.")
                    }
                    else {
                        SVProgressHUD.dismiss()
                    }
                    
                }
            }
        }
    }
    
    public func unwrappedValues() -> [String: Any] {
        let wrapped = form.values(includeHidden: true)
//        var unwrapped = [String: Any]()
        var unwrapped = GParams()
                
        for (k, v) in wrapped {
            if let rowValue = self.form.rowBy(tag: k)?.baseValue as? KeyValue {
                unwrapped[k] = rowValue.value
            }
            else {
                unwrapped[k] = v
            }
        }
        
        return unwrapped
    }
    
    public func clearFields(_ tableView: UITableView) {
        let section = form.allSections.last
        section?.removeAll()
        
        let urlRequest = URLRequest(url: URL(string: formURL)!)
        if let cachedResponse = URLCache.shared.cachedResponse(for: urlRequest) {
            let htmlString = String(data: cachedResponse.data, encoding: .utf8)
            let docCached = Kanna.HTML(html: htmlString!, encoding: .utf8)
            processDocument(doc: docCached!)
        }
        
        tableView.reloadData()
    }
    
    private func processDocument(doc: HTMLDocument) {
        self.rendered = true
        self.section = form.allSections.last!
        self.document = doc
        let formElement = doc.css("form").first
        self.formAction = formElement?["action"]
        if let inputs = formElement?.css("input, select, textarea") {
            for input in inputs {
                let name = input["name"] ?? ""
                var label = input.parent?.at_css("label")?.text ?? ""
            
                switch(input.tagName!) {
                case "textarea":
                    textAreaRow(input, name: name)
                    break
                case "select":
                    let options = input.css("option").map({ (element) -> KeyValue in
                        return KeyValue(text: element.text!, value: element["value"]!)
                    })
                    
                    pushRow(input, name: name, label: label, options: options)
                    break
                case "input":
                    switch(input["type"] ?? "") {
                    case "text":
                        label = input.parent?.parent?.at_css("label")?.text ?? ""
                    
                        if (input.className?.contains("date_picker"))! {
                            dateRow(input, name: name, label: label)
                        }
                        else {
                            if (input.className?.contains("datetime_picker"))! {
                                dateTimeRow(input, name: name, label: label)
                            }
                            else {
                                if (input.className?.contains("time_picker"))! {
                                    timeRow(input, name: name, label: label)
                                }
                                else {
                                    label = input.parent?.at_css("label")?.text ?? ""
                                    textRow(input, name: name, label: label)
                                }
                            }
                        }
                        break
                    case "email":
                        emailRow(input, name: name, label: label)
                        break
                    case "password":
                        passwordRow(input, name: name, label: label)
                        break
                    case "url":
                        urlRow(input, name: name, label: label)
                        break
                    case "hidden":
                        // NOTE: Not sure what this is for
//                        let hiddenFields = formElement?.css("input[name=\(name)]")
//                    
//                        if hiddenFields?.count == 1 {
//                            hiddenRow(input, name: name)
//                        }
                        hiddenRow(input, name: name)
                        break
                    case "radio":
                        if (self.form.rowBy(tag: name) != nil) {
                            continue
                        }
                    
                        let options = formElement?.css("input[name=\(name)]").map({ (element) -> String in
                            return element["value"] ?? ""
                        }).filter { $0 != "" }
                    
                        pushRow(input, name: name, label: "", options: options!)
                        break
                    case "checkbox":
                        if (self.form.rowBy(tag: name) != nil) {
                            continue
                        }
                    
                        if (input["name"]?.contains("[]"))! {
                            let checkBoxes = formElement?.css("input[name=\(name)]")
                            let options = checkBoxes?.map({ (element) -> String in
                                return element["value"] ?? ""
                            }).filter { $0 != "" }
                        
                            multipleSelectorRow(input, name: name, label: "", options: options!)
                        }
                        else {
                            label = (input.parent?.text)!
                            switchRow(input, name: name, label: label)
                        }
                        break
                    case "tel":
                        phoneRow(input, name: name, label: label)
                        break
                    case "file":
                        imageRow(input, name: name, label: label)
                    case "submit":
                        submitButtonRow(input, name: name)
                        break
                    case "data_list":
                        let options = input.parent?.css("option").map({ (element) -> String in
                            return element["value"] ?? ""
                        })
                        dataListRow(input, name: name, label: label, options: options!)
                        break
                    default: break
                    }
                    break
                default: break
                }
            }
        }
        else {
            SVProgressHUD.showInfo(withStatus: "Form changed, pull to refresh")
        }
    }
    
    private func responseStatusSuccess(response: DataResponse<String>) -> Bool {
        if response.error == nil {
            if let statusCode = response.response?.statusCode {
                if statusCode >= 200 && statusCode < 300 {
                    return true
                }
            }
        }
        
        return false
    }
    
    private func replaceSection(row: BaseRow, at: Int!) {
        section.remove(at: at)
        section.insert(row, at: at)
    }
    
    private func textAreaRow(_ input: XMLElement, name: String) {
        let textAreaRow = HTMLTextAreaRow(name) { row in
            var value = input.text
            if let range = value?.range(of: "\n") {
                value?.replaceSubrange(range, with: "")
            }
            
            row.html        = input.toHTML
            row.title       = input.parent?.at_css("label")?.text ?? ""
            row.placeholder = input["placeholder"] ?? ""
            row.value       = value
        }
        
        if let inputRow: HTMLTextAreaRow = form.rowBy(tag: name) {
            if input.toHTML != inputRow.html! {
                let index = section.index(of: inputRow)
                replaceSection(row: textAreaRow, at: index)
            }
        }
        else {
            section <<< textAreaRow
        }
    }
    
    private func textRow(_ input: XMLElement, name: String, label: String) {
        let textRow = HTMLTextRow(name) { row in
            row.html  = input.toHTML
            row.value = input["value"] ?? ""
            row.title = label
        }
        
        if let inputRow: HTMLTextRow = form.rowBy(tag: name) {
            if input.toHTML != inputRow.html! {
                let index = section.index(of: inputRow)
                replaceSection(row: textRow, at: index)
            }
        }
        else {
            section <<< textRow
        }
    }
    
    private func dateTimeRow(_ input: XMLElement, name: String, label: String) {
        let dateRow = HTMLDateTimeRow(name) { row in
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm"
            row.value = formatter.date(from: input["value"] ?? "")
            row.html  = input.toHTML
            row.title = label
        }
        
        if let inputRow: HTMLDateTimeRow = form.rowBy(tag: name) {
            if input.toHTML != inputRow.html! {
                let index = section.index(of: inputRow)
                replaceSection(row: dateRow, at: index)
            }
        }
        else {
            section <<< dateRow
        }
    }
    
    private func dateRow(_ input: XMLElement, name: String, label: String) {
        let dateRow = HTMLDateRow(name) { row in
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            row.value = formatter.date(from: input["value"] ?? "")
            row.html  = input.toHTML
            row.title = label
        }
        
        if let inputRow: HTMLDateRow = form.rowBy(tag: name) {
            if input.toHTML != inputRow.html! {
                let index = section.index(of: inputRow)
                replaceSection(row: dateRow, at: index)
            }
        }
        else {
            section <<< dateRow
        }
    }
    
    private func timeRow(_ input: XMLElement, name: String, label: String) {
        let timeRow = HTMLTimeRow(name) { row in
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            row.value = formatter.date(from: input["value"] ?? "")
            row.html  = input.toHTML
            row.title = label
        }
        
        if let inputRow: HTMLTimeRow = form.rowBy(tag: name) {
            if input.toHTML != inputRow.html! {
                let index = section.index(of: inputRow)
                replaceSection(row: timeRow, at: index)
            }
        }
        else {
            section <<< timeRow
        }
    }
    
    private func pushRow(_ input: XMLElement, name: String, label: String, options: [String]) {
        let pushRow = HTMLPushRow<String>(name) { row in
            row.html    = input.toHTML
            row.title   = label
            row.options = options
            row.value   = options.first
        }
        
        if let inputRow: HTMLPushRow<String> = form.rowBy(tag: name) {
            if input.toHTML != inputRow.html! {
                let index = section.index(of: inputRow)
                replaceSection(row: pushRow, at: index)
            }
        }
        else {
            section <<< pushRow
        }
    }
    
    private func pushRow(_ input: XMLElement, name: String, label: String, options: [KeyValue]) {
        let pushRow = HTMLPushRow<KeyValue>(name) { row in
            row.html    = input.toHTML
            row.title   = label
            row.options = options
            row.value   = options.first
        }
        
        if let inputRow: HTMLPushRow<KeyValue> = form.rowBy(tag: name) {
            if input.toHTML != inputRow.html! {
                let index = section.index(of: inputRow)
                replaceSection(row: pushRow, at: index)
            }
        }
        else {
            section <<< pushRow
        }
    }
    
    private func dataListRow(_ input: XMLElement, name: String, label: String, options: [String]) {
        let dataListRow = HtmlDataListRow<String>(name) { row in
            row.html    = input.toHTML
            row.title   = label
            row.options = options
            row.value   = options.first
        }
        
        if let inputRow: HtmlDataListRow<String> = form.rowBy(tag: name) {
            if input.toHTML != inputRow.html! {
                let index = section.index(of: inputRow)
                replaceSection(row: dataListRow, at: index)
            }
        }
        else {
            section <<< dataListRow
        }
    }
    
    private func emailRow(_ input: XMLElement, name: String, label: String) {
        let emailRow = HTMLEmailRow(name) { row in
            row.html  = input.toHTML
            row.title = label
            row.value = input["value"] ?? ""
        }
        
        if let inputRow: HTMLEmailRow = form.rowBy(tag: name) {
            if input.toHTML != inputRow.html! {
                let index = section.index(of: inputRow)
                replaceSection(row: emailRow, at: index)
            }
        }
        else {
            section <<< emailRow
        }
    }
    
    private func passwordRow(_ input: XMLElement, name: String, label: String) {
        let passwordRow = HTMLPasswordRow(name) { row in
            row.html  = input.toHTML
            row.title = label
            row.value = input["value"] ?? ""
        }
        
        if let inputRow: HTMLPasswordRow = form.rowBy(tag: name) {
            if input.toHTML != inputRow.html! {
                let index = section.index(of: inputRow)
                replaceSection(row: passwordRow, at: index)
            }
        }
        else {
            section <<< passwordRow
        }
    }
    
    private func urlRow(_ input: XMLElement, name: String, label: String) {
        let urlRow = HTMLURLRow(name) { row in
            row.html  = input.toHTML
            row.title = label
            row.value = URL(string: input["value"] ?? "")
        }
        
        if let inputRow: HTMLURLRow = form.rowBy(tag: name) {
            if input.toHTML != inputRow.html! {
                let index = section.index(of: inputRow)
                replaceSection(row: urlRow, at: index)
            }
        }
        else {
            section <<< urlRow
        }
    }
    
    private func hiddenRow(_ input: XMLElement, name: String) {
        let hiddenRow = HTMLTextRow(name) { row in
            row.html   = input.toHTML
            row.value  = input["value"] ?? ""
            row.hidden = true
        }
        
        if let inputRow: HTMLTextRow = form.rowBy(tag: name) {
            if input.toHTML != inputRow.html! {
                // Index will be nil if the field was previously also a hidden field.
                if let index = section.index(of: inputRow) {
                    replaceSection(row: hiddenRow, at: index)
                }
                else {
                    inputRow.html  = hiddenRow.html
                    inputRow.value = hiddenRow.value
                    inputRow.updateCell()
                }

                // Since hidden row not present in section
                // just update the value
//                inputRow.html  = hiddenRow.html
//                inputRow.value = hiddenRow.value
//                inputRow.updateCell()
                
//                print(name)
//                print(inputRow.value)
//                print(form.values(includeHidden: true))
            }
        }
        else {
            section <<< hiddenRow
        }
    }
    
    private func multipleSelectorRow(_ input: XMLElement,
                                     name: String,
                                     label: String,
                                     options: [String]) {
        let multipleSelectorRow = HTMLMultipleSelectorRow<String>(name) { row in
            row.html    = input.toHTML
            row.title   = label
            row.options = options
        }
        
        if let inputRow: HTMLMultipleSelectorRow<String> = form.rowBy(tag: name) {
            if input.toHTML != inputRow.html! {
                let index = section.index(of: inputRow)
                replaceSection(row: multipleSelectorRow, at: index)
            }
        }
        else {
            section <<< multipleSelectorRow
        }
    }
    
    private func switchRow(_ input: XMLElement, name: String, label: String) {
        let switchRow = HTMLSwitchRow(name) { row in
            row.html  = input.toHTML
            row.title = label
            row.value = input["checked"] == "checked"
        }.cellUpdate { (cell, row) in
            cell.textLabel?.numberOfLines = 0
            cell.textLabel?.font = cell.textLabel?.font.withSize(14)
        }
        
        if let inputRow: HTMLSwitchRow = form.rowBy(tag: name) {
            if input.toHTML != inputRow.html! {
                let index = section.index(of: inputRow)
                replaceSection(row: switchRow, at: index)
            }
        }
        else {
            section <<< switchRow
        }
    }
    
    private func phoneRow(_ input: XMLElement, name: String, label: String) {
        let phoneRow = HTMLPhoneRow(name) { row in
            row.html  = input.toHTML
            row.title = label
            row.value = input["value"] ?? ""
        }
        
        if let inputRow: HTMLPhoneRow = form.rowBy(tag: name) {
            if input.toHTML != inputRow.html! {
                let index = section.index(of: inputRow)
                replaceSection(row: phoneRow, at: index)
            }
        }
        else {
            section <<< phoneRow
        }
    }
    
    private func imageRow(_ input: XMLElement, name: String, label: String) {
        /* TODO: Fix
        let imageRow = HTMLImageRow(name) { row in
            row.html        = input.toHTML
            row.title       = label
            row.sourceTypes = [.PhotoLibrary, .Camera, .SavedPhotosAlbum]
            row.clearAction = .yes(style: UIAlertActionStyle.destructive)
        }
        
        if let inputRow: HTMLImageRow = form.rowBy(tag: name) {
            if input.toHTML != inputRow.html! {
                let index = section.index(of: inputRow)
                replaceSection(row: imageRow, at: index)
            }
        }
        else {
            section <<< imageRow
        }
 */
    }
    
    private func submitButtonRow(_ input: XMLElement, name: String) {
        let buttonRow = HTMLButtonRow(name) { row in
            row.html    = input.toHTML
            row.title   = input["value"] ?? ""
        }.onCellSelection { (cell, row) in
//            self.delegate?.onSubmit(htmlForm: self)
            self.submit()
        }
        
        if let inputRow: HTMLButtonRow = form.rowBy(tag: name) {
            if input.toHTML != inputRow.html! {
                let index = section.index(of: inputRow)
                replaceSection(row: buttonRow, at: index)
            }
        }
        else {
            section <<< buttonRow
        }
    }
    
    private func submit() {
        if let path = formAction {
            SVProgressHUD.show()
            
            Rest.post(path: "/\(path).json", params: unwrappedValues(), headers: headers()).execute { json in
                SVProgressHUD.dismiss()
                self.onSubmitSucceeded(json)
                return true
            }
            
//            Alamofire.request("\(GHttp.instance.host())\(path).json",
//                method: .post,
//                parameters: unwrappedValues(),
//                headers: headers()).responseString { response in
//                    switch response.result {
//                    case .success(let value):
//                        let json = JSON(parseJSON: value)
//                        
//                        SVProgressHUD.dismiss()
//                        self.onSubmitSucceeded(json)
//                    }
//                    case .failure(let error):
//                        SVProgressHUD.showError(withStatus: error.localizedDescription)
//                    }
//            }
        }
    }
}
