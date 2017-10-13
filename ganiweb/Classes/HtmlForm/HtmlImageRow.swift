import Eureka
import GaniLib

// See https://stackoverflow.com/questions/38813906/swift-3-how-to-use-preprocessor-flags-like-if-debug-to-implement-api-keys
#if INCLUDE_IMAGEROW

import ImageRow

public final class HtmlImageRow: _ImageRow<PushSelectorCell<UIImage>>, RowType {
    var html: String?

    public required init(tag: String?) {
        super.init(tag: tag)
    }
}

#endif

