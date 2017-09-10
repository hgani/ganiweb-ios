import Eureka
//import ImageRow

protocol HtmlFormRow {
    var html: String? { get }
}

public final class HTMLTextAreaRow: _TextAreaRow, RowType, HtmlFormRow {
    var html: String?
    
    required public init(tag: String?) {
        super.init(tag: tag)
    }
}

public final class HTMLPushRow<T: Equatable>: _PushRow<PushSelectorCell<T>>, RowType, HtmlFormRow {
    var html: String?
    
    required public init(tag: String?) {
        super.init(tag: tag)
    }
}

public final class HTMLTextRow: _TextRow, RowType, HtmlFormRow {
    var html: String?
    
    required public init(tag: String?) {
        super.init(tag: tag)
    }
}

public final class HTMLDateRow: _DateRow, RowType, HtmlFormRow {
    var html: String?
    
    required public init(tag: String?) {
        super.init(tag: tag)
    }
}


public final class HTMLTimeRow: _TimeRow, RowType, HtmlFormRow {
    var html: String?
    
    required public init(tag: String?) {
        super.init(tag: tag)
    }
}

public final class HTMLDateTimeRow: _DateTimeRow, RowType, HtmlFormRow {
    var html: String?
    
    required public init(tag: String?) {
        super.init(tag: tag)
    }
}

public final class HTMLEmailRow: _EmailRow, RowType, HtmlFormRow {
    var html: String?
    
    required public init(tag: String?) {
        super.init(tag: tag)
    }
}

public final class HTMLPasswordRow: _PasswordRow, RowType, HtmlFormRow {
    var html: String?
    
    required public init(tag: String?) {
        super.init(tag: tag)
    }
}

public final class HTMLURLRow: _URLRow, RowType, HtmlFormRow {
    var html: String?
    
    required public init(tag: String?) {
        super.init(tag: tag)
    }
}

public final class HTMLMultipleSelectorRow<T: Hashable>:
    _MultipleSelectorRow<T, PushSelectorCell<Set<T>>>, RowType, HtmlFormRow {
    var html: String?
    
    public required init(tag: String?) {
        super.init(tag: tag)
    }
}

public final class HTMLSwitchRow: _SwitchRow, RowType, HtmlFormRow {
    var html: String?
    
    required public init(tag: String?) {
        super.init(tag: tag)
    }
}

public final class HTMLPhoneRow: _PhoneRow, RowType, HtmlFormRow {
    var html: String?
    
    required public init(tag: String?) {
        super.init(tag: tag)
    }
}

public final class HTMLButtonRowOf<T: Equatable>: _ButtonRowOf<T>, RowType, HtmlFormRow {
    var html: String?
    
    required public init(tag: String?) {
        super.init(tag: tag)
    }
}
public typealias HTMLButtonRow = HTMLButtonRowOf<String>

/*
public final class HTMLImageRow: _ImageRow<PushSelectorCell<UIImage>>, RowType {
    var html: String?
    
    public required init(tag: String?) {
        super.init(tag: tag)
    }
}
*/

public final class AACCheckCell: Cell<Bool>, CellType {
    
    required public init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    open override func update() {
        super.update()
        accessoryType = row.value == true ? .checkmark : .none
        editingAccessoryType = accessoryType
        selectionStyle = .default
        
        detailTextLabel?.textColor = .gray
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        tintColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        if row.isDisabled {
            tintColor = UIColor(red: red, green: green, blue: blue, alpha: 0.3)
            selectionStyle = .none
        } else {
            tintColor = UIColor(red: red, green: green, blue: blue, alpha: 1)
        }
    }
    
    open override func setup() {
        super.setup()
        accessoryType = .checkmark
        editingAccessoryType = accessoryType
    }
    
    open override func didSelect() {
        row.value = row.value ?? false ? false : true
        row.deselect()
        row.updateCell()
    }
    
}

open class _AACCheckRow: Row<AACCheckCell> {
    
    required public init(tag: String?) {
        super.init(tag: tag)
        displayValueFor = nil
    }
}

public final class AACCheckRow: _AACCheckRow, RowType {
    required public init(tag: String?) {
        super.init(tag: tag)
    }
}
