import Eureka
import GaniLib

open class _HtmlDataListRow<Cell: CellType>: SelectorRow<Cell> where Cell: BaseCell, Cell.Value == String {
    public required init(tag: String?) {
        super.init(tag: tag)
        
        presentationMode = .show(controllerProvider: ControllerProvider.callback { return HtmlDataListSelectorViewController<SelectorRow<Cell>>() }, onDismiss: { vc in
            // Nothing to do
        })
    }
}

public final class HtmlDataListRow: _HtmlDataListRow<PushSelectorCell<String>>, RowType {
    var html: String?
    
    public required init(tag: String?) {
        super.init(tag: tag)
    }
}

private class HtmlDataListSelectorViewController<OptionsRow: OptionsProviderRow>: SelectorViewController<OptionsRow> where OptionsRow.OptionsProviderType.Option == String {
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        appendTextRow()
    }
    
    private func appendTextRow() {
        let section = form.allSections.first!
        let row = TextRow() { row in
            row.title = "Other (Please specify)"
            }.cellSetup { (cell, row) in
                for option in self.optionsProviderRow.optionsProvider?.optionsArray ?? [] {
                    if self.row.value == option {
                        return
                    }
                }
                // Only initialize the text field when no option is selected
                row.value = self.row.value
            }.cellUpdate { (_, row) in
                let changed = self.row.value != (row.value ?? "")
                if row.value != nil && changed {
                    self.row.value = row.value
                    self.row.reload()  // Reflect the change in UI
                    self.onDismissCallback?(self)
                }
        }
        
        section <<< row
    }
}
