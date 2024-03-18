public struct BasicCell: Cell {
    public let value: String
    public let width: Int

    public init(_ v: String, _ w: Int) {
        self.value = v
        self.width = w
    }
}

extension BasicCell {
    public init(_ str: String) {
        self.value = str
        self.width = str.count
    }
}
