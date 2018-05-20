import GaniLib

import Eureka
import Alamofire
import Kanna
import SVProgressHUD
import SwiftyJSON

public class HtmlForm {
    let form: Form
    
    var section: Section!
    private var formAction: String!
    var document: HTMLDocument!
    
    private let onSubmitSucceeded: ((JSON)->Void)
    
    public private(set) var rendered = false
    
    init(form: Form, onSubmitSucceeded: @escaping ((JSON)->Void)) {
        self.form = form
        self.onSubmitSucceeded = onSubmitSucceeded
    }
    
    public static func preload(paths: [String]) {
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
            "X-CSRF-Token": csrfToken ?? "",
        ]
    }
    
    private func populateFromCache(path: String) {
        let urlRequest = URLRequest(url: URL(string: "\(GHttp.instance.host())\(path)")!)
        if let cachedResponse = URLCache.shared.cachedResponse(for: urlRequest) {
            if let htmlString = String(data: cachedResponse.data, encoding: .utf8) {
                if let cachedDoc = try? Kanna.HTML(html: htmlString, encoding: .utf8) {
                    processWithoutAnimation(doc: cachedDoc, path: path)
                }
            }
        }
    }
    
    public func load(_ path: String, indicator: ProgressIndicator, onSuccess: (()->Void)? = nil) {
        populateFromCache(path: path)
        
        Http.get(path: path).execute(indicator: indicator) { content in
            if let doc = try? Kanna.HTML(html: content, encoding: .utf8) {
                self.processWithoutAnimation(doc: doc, path: path)
                onSuccess?()
                return nil
            }
            return "Invalid content"
        }
    }
    
    private func unwrappedValues() -> GParams {
        let wrapped = form.values(includeHidden: true)
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
    
//    public func clearFields(_ tableView: UITableView) {
//        let section = form.allSections.last
//        section?.removeAll()
//        
//        populateFromCache()
//        
////        let urlRequest = URLRequest(url: URL(string: formURL)!)
////        if let cachedResponse = URLCache.shared.cachedResponse(for: urlRequest) {
////            let htmlString = String(data: cachedResponse.data, encoding: .utf8)
////            let docCached = Kanna.HTML(html: htmlString!, encoding: .utf8)
////            processDocument(doc: docCached!)
////        }
//        
////        tableView.reloadData()
//    }
    
    private func deleteObsoleteRows(inputs: Kanna.XPathObject) {
        var names = [String]()
        for input in inputs {
            if let name = input["name"] {
                names.append(name)
            }
        }
        
        for row in form.rows {
            if let tag = row.tag, !names.contains(tag), let index = section.index(of: row) {
                section.remove(at: index)
            }
        }
    }
    
    private func processWithoutAnimation(doc: HTMLDocument, path: String) {
        // Avoid jumpiness as fields get removed and inserted.
        UIView.performWithoutAnimation {
            self.process(doc: doc, path: path)
        }
    }
    
    private func process(doc: HTMLDocument, path: String) {
        self.rendered = true
        self.section = form.allSections.last!
        self.document = doc
        if let formElement = doc.css("form").first {
            self.formAction = formElement["action"]
            if let action = formAction, action.count <= 0 {
                self.formAction = path
            }
            
            let inputs = formElement.css("input, textarea, select, button")

            deleteObsoleteRows(inputs: inputs)
            
            for input in inputs {
                let name = input["name"] ?? ""
                let label = input.parent?.at_css("label")?.text ?? ""
                
                switch(input.tagName!) {
                case "input":
                    inputRow(from: input, name: name, label: label, formElement: formElement)
                    break
                case "textarea":
                    textAreaRow(input, name: name)
                    break
                case "select":
                    let options = input.css("option").map({ (element) -> KeyValue in
                        return KeyValue(text: element.text!, value: element["value"]!)
                    })
                    
                    pushRow(input, name: name, label: label, options: options)
                    break
                case "button":
                    let type = input["type"]
                    if type == nil || type == "submit" {
                        submitButtonRow(input, name: name, text: input.text ?? "", action: input["formaction"])
                    }
                    break
                default: break
                }
            }
        }
        else {
            SVProgressHUD.showInfo(withStatus: "Can't find form data")
        }
//        }
    }
    
    private func jsDateTimeLabel(from input: XMLElement) -> String {
        return input.parent?.parent?.at_css("label")?.text ?? ""
    }
    
    // TODO: Refactor to support html5 date/datetime field
    private func inputRow(from input: XMLElement, name: String, label: String, formElement: XMLElement) {
        switch(input["type"] ?? "") {
        case "text":
//            let label = input.parent?.parent?.at_css("label")?.text ?? ""
            
            if (input.className?.contains("date_picker"))! {
                dateRow(input, name: name, label: jsDateTimeLabel(from: input))
            }
            else if (input.className?.contains("datetime_picker"))! {
                dateTimeRow(input, name: name, label: jsDateTimeLabel(from: input))
            }
            else if (input.className?.contains("time_picker"))! {
                timeRow(input, name: name, label: jsDateTimeLabel(from: input))
            }
            else {
                //                        label = input.parent?.at_css("label")?.text ?? ""
                textRow(input, name: name, label: label)
            }
            
//            else {
//                if (input.className?.contains("datetime_picker"))! {
//                    dateTimeRow(input, name: name, label: label)
//                }
//                else {
//                    if (input.className?.contains("time_picker"))! {
//                        timeRow(input, name: name, label: label)
//                    }
//                    else {
////                        label = input.parent?.at_css("label")?.text ?? ""
//                        textRow(input, name: name, label: label)
//                    }
//                }
//            }
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
            hiddenRow(input, name: name)
            break
        case "radio":
            if (self.form.rowBy(tag: name) != nil) {
//                continue
                return
            }
            
            let options = formElement.css("input[name=\(name)]").map({ (element) -> String in
                return element["value"] ?? ""
            }).filter { $0 != "" }
            
            pushRow(input, name: name, label: "", options: options)
            break
        case "checkbox":
            if (self.form.rowBy(tag: name) != nil) {
//                continue
                return
            }
            
            if (input["name"]?.contains("[]"))! {
                let checkBoxes = formElement.css("input[name=\(name)]")
                let options = checkBoxes.map({ (element) -> String in
                    return element["value"] ?? ""
                }).filter { $0 != "" }
                
                multipleSelectorRow(input, name: name, label: "", options: options)
            }
            else {
//                label = (input.parent?.text)!
                switchRow(input, name: name, label: label)
            }
            break
        case "tel":
            phoneRow(input, name: name, label: label)
            break
        case "file":
            imageRow(input, name: name, label: label)
        case "submit":
            submitButtonRow(input, name: name, text: input["value"] ?? "", action: nil)
            break
        case "data_list":
            let options = input.parent?.css("option").map({ (element) -> String in
                return element["value"] ?? ""
            })
            dataListRow(input, name: name, label: label, options: options!)
            break
        default: break
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
    
    private func insertOrReplaceRow(_ row: BaseRow, tag: String) {
        if let inputRow = form.rowBy(tag: tag) {
            if (row as? HtmlFormRow)?.html != (inputRow as? HtmlFormRow)?.html! {
//                let index = section.index(of: inputRow)
//                replaceSection(row: row, at: index)
                
                // In the case of hidden field, index will be nil if the field was previously also a hidden field.
                if let index = section.index(of: inputRow) {
                    replaceSection(row: row, at: index)
                }
                else {
                    let destination = inputRow as! HTMLTextRow
                    let source = row as! HTMLTextRow
                    destination.html  = source.html
                    destination.value = source.value
                    destination.updateCell()
                }
            }
            else {
                if let index = section.index(of: inputRow) {
                    // Reposition
                    section.remove(at: index)
                    section.append(inputRow)
                }
            }
        }
        else {
            section <<< row
        }
    }
    
    private func hiddenRow(_ input: XMLElement, name: String) {
        let hiddenRow = HTMLTextRow(name) { row in
            row.html   = input.toHTML
            row.value  = input["value"] ?? ""
            row.hidden = true
        }
        insertOrReplaceRow(hiddenRow, tag: name)
        
        //        if let inputRow: HTMLTextRow = form.rowBy(tag: name) {
        //            if input.toHTML != inputRow.html! {
        //                // Index will be nil if the field was previously also a hidden field.
        //                if let index = section.index(of: inputRow) {
        //                    replaceSection(row: hiddenRow, at: index)
        //                }
        //                else {
        //                    inputRow.html  = hiddenRow.html
        //                    inputRow.value = hiddenRow.value
        //                    inputRow.updateCell()
        //                }
        //            }
        //        }
        //        else {
        //            section <<< hiddenRow
        //        }
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
        insertOrReplaceRow(textAreaRow, tag: name)
    }
    
    private func textRow(_ input: XMLElement, name: String, label: String) {
        let textRow = HTMLTextRow(name) { row in
            row.html  = input.toHTML
            row.value = input["value"] ?? ""
            row.title = label
        }
        insertOrReplaceRow(textRow, tag: name)
    }
    
    private func dateTimeRow(_ input: XMLElement, name: String, label: String) {
        let dateRow = HTMLDateTimeRow(name) { row in
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm"
            row.value = formatter.date(from: input["value"] ?? "")
            row.html  = input.toHTML
            row.title = label
        }
        insertOrReplaceRow(dateRow, tag: name)
//        if let inputRow: HTMLDateTimeRow = form.rowBy(tag: name) {
//            if input.toHTML != inputRow.html! {
//                let index = section.index(of: inputRow)
//                replaceSection(row: dateRow, at: index)
//            }
//        }
//        else {
//            section <<< dateRow
//        }
    }
    
    private func dateRow(_ input: XMLElement, name: String, label: String) {
        let dateRow = HTMLDateRow(name) { row in
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            row.value = formatter.date(from: input["value"] ?? "")
            row.html  = input.toHTML
            row.title = label
        }
        insertOrReplaceRow(dateRow, tag: name)
        
//        if let inputRow: HTMLDateRow = form.rowBy(tag: name) {
//            if input.toHTML != inputRow.html! {
//                let index = section.index(of: inputRow)
//                replaceSection(row: dateRow, at: index)
//            }
//        }
//        else {
//            section <<< dateRow
//        }
    }
    
    private func timeRow(_ input: XMLElement, name: String, label: String) {
        let timeRow = HTMLTimeRow(name) { row in
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            row.value = formatter.date(from: input["value"] ?? "")
            row.html  = input.toHTML
            row.title = label
        }
        insertOrReplaceRow(timeRow, tag: name)
        
//        if let inputRow: HTMLTimeRow = form.rowBy(tag: name) {
//            if input.toHTML != inputRow.html! {
//                let index = section.index(of: inputRow)
//                replaceSection(row: timeRow, at: index)
//            }
//        }
//        else {
//            section <<< timeRow
//        }
    }
    
    private func pushRow(_ input: XMLElement, name: String, label: String, options: [String]) {
        let pushRow = HTMLPushRow<String>(name) { row in
            row.html    = input.toHTML
            row.title   = label
            row.options = options
            row.value   = options.first
        }
        insertOrReplaceRow(pushRow, tag: name)
        
//        if let inputRow: HTMLPushRow<String> = form.rowBy(tag: name) {
//            if input.toHTML != inputRow.html! {
//                let index = section.index(of: inputRow)
//                replaceSection(row: pushRow, at: index)
//            }
//        }
//        else {
//            section <<< pushRow
//        }
    }
    
    private func pushRow(_ input: XMLElement, name: String, label: String, options: [KeyValue]) {
        let pushRow = HTMLPushRow<KeyValue>(name) { row in
            row.html    = input.toHTML
            row.title   = label
            row.options = options
            row.value   = options.first
        }
        insertOrReplaceRow(pushRow, tag: name)
        
//        if let inputRow: HTMLPushRow<KeyValue> = form.rowBy(tag: name) {
//            if input.toHTML != inputRow.html! {
//                let index = section.index(of: inputRow)
//                replaceSection(row: pushRow, at: index)
//            }
//        }
//        else {
//            section <<< pushRow
//        }
    }
    
    private func dataListRow(_ input: XMLElement, name: String, label: String, options: [String]) {
        let dataListRow = HtmlDataListRow(name) { row in
            row.html    = input.toHTML
            row.title   = label
            row.options = options
            row.value   = options.first
        }
        insertOrReplaceRow(dataListRow, tag: name)
        
//        if let inputRow: HtmlDataListRow = form.rowBy(tag: name) {
//            if input.toHTML != inputRow.html! {
//                let index = section.index(of: inputRow)
//                replaceSection(row: dataListRow, at: index)
//            }
//        }
//        else {
//            section <<< dataListRow
//        }
    }
    
    private func emailRow(_ input: XMLElement, name: String, label: String) {
        let emailRow = HTMLEmailRow(name) { row in
            row.html  = input.toHTML
            row.title = label
            row.value = input["value"] ?? ""
        }
        insertOrReplaceRow(emailRow, tag: name)
        
//        if let inputRow: HTMLEmailRow = form.rowBy(tag: name) {
//            if input.toHTML != inputRow.html! {
//                let index = section.index(of: inputRow)
//                replaceSection(row: emailRow, at: index)
//            }
//        }
//        else {
//            section <<< emailRow
//        }
    }
    
    private func passwordRow(_ input: XMLElement, name: String, label: String) {
        let passwordRow = HTMLPasswordRow(name) { row in
            row.html  = input.toHTML
            row.title = label
            row.value = input["value"] ?? ""
        }
        insertOrReplaceRow(passwordRow, tag: name)
        
//        if let inputRow: HTMLPasswordRow = form.rowBy(tag: name) {
//            if input.toHTML != inputRow.html! {
//                let index = section.index(of: inputRow)
//                replaceSection(row: passwordRow, at: index)
//            }
//        }
//        else {
//            section <<< passwordRow
//        }
    }
    
    private func urlRow(_ input: XMLElement, name: String, label: String) {
        let urlRow = HTMLURLRow(name) { row in
            row.html  = input.toHTML
            row.title = label
            row.value = URL(string: input["value"] ?? "")
        }
        insertOrReplaceRow(urlRow, tag: name)
        
//        if let inputRow: HTMLURLRow = form.rowBy(tag: name) {
//            if input.toHTML != inputRow.html! {
//                let index = section.index(of: inputRow)
//                replaceSection(row: urlRow, at: index)
//            }
//        }
//        else {
//            section <<< urlRow
//        }
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
        insertOrReplaceRow(multipleSelectorRow, tag: name)
        
//        if let inputRow: HTMLMultipleSelectorRow<String> = form.rowBy(tag: name) {
//            if input.toHTML != inputRow.html! {
//                let index = section.index(of: inputRow)
//                replaceSection(row: multipleSelectorRow, at: index)
//            }
//        }
//        else {
//            section <<< multipleSelectorRow
//        }
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
        insertOrReplaceRow(switchRow, tag: name)
        
//        if let inputRow: HTMLSwitchRow = form.rowBy(tag: name) {
//            Log.t("SWITCH1")
//            if input.toHTML != inputRow.html! {
//                let index = section.index(of: inputRow)
//                replaceSection(row: switchRow, at: index)
//            }
//        }
//        else {
//            section <<< switchRow
//        }
    }
    
    private func phoneRow(_ input: XMLElement, name: String, label: String) {
        let phoneRow = HTMLPhoneRow(name) { row in
            row.html  = input.toHTML
            row.title = label
            row.value = input["value"] ?? ""
        }
        insertOrReplaceRow(phoneRow, tag: name)
        
//        if let inputRow: HTMLPhoneRow = form.rowBy(tag: name) {
//            if input.toHTML != inputRow.html! {
//                let index = section.index(of: inputRow)
//                replaceSection(row: phoneRow, at: index)
//            }
//        }
//        else {
//            section <<< phoneRow
//        }
    }
    
    private func imageRow(_ input: XMLElement, name: String, label: String) {
        #if INCLUDE_IMAGEROW

        let imageRow = HtmlImageRow(name) { row in
            row.html        = input.toHTML
            row.title       = label
            row.sourceTypes = [.PhotoLibrary, .Camera, .SavedPhotosAlbum]
            row.clearAction = .yes(style: UIAlertActionStyle.destructive)
        }
        insertOrReplaceRow(imageRow, tag: name)

//        if let inputRow: HtmlImageRow = form.rowBy(tag: name) {
//            if input.toHTML != inputRow.html! {
//                let index = section.index(of: inputRow)
//                replaceSection(row: imageRow, at: index)
//            }
//        }
//        else {
//            section <<< imageRow
//        }
        
        #endif
    }
    
    private func submitButtonRow(_ input: XMLElement, name: String, text: String, action: String?) {
        let buttonRow = HTMLButtonRow(name) { row in
            row.html = input.toHTML
            row.title = text
//            row.title   = input["value"] ?? ""
        }.onCellSelection { [unowned self] (cell, row) in
            self.submit(action: action)
        }
        insertOrReplaceRow(buttonRow, tag: name)
    }
    
    private func isMultipart(params: GParams) -> Bool {
        for (_, value) in params {
            if value is UIImage {
                return true
            }
        }
        return false
    }
    
    private func submit(action: String?) {
        if let path = action ?? formAction {
            SVProgressHUD.show()
            
            let params = unwrappedValues()
            if isMultipart(params: params) {
                _ = Rest.multipart(path: "\(path).json", params: params, headers: headers()).execute { json in
                    SVProgressHUD.dismiss()
                    self.onSubmitSucceeded(json)
                    return true
                }
            }
            else {
                _ = Rest.post(path: "\(path).json", params: unwrappedValues(), headers: headers()).execute { json in
                    SVProgressHUD.dismiss()
                    self.onSubmitSucceeded(json)
                    return true
                }
            }
        }
    }
}
