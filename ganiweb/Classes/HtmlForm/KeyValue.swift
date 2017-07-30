struct KeyValue: CustomStringConvertible {
    var text: String
    var value: String
    
    init(text: String, value: String) {
        self.text = text
        self.value = value
    }
    
    var description: String { return text }
}

extension KeyValue: Equatable {}

func ==(lhs: KeyValue, rhs: KeyValue) -> Bool {
    return lhs.value == rhs.value
}
