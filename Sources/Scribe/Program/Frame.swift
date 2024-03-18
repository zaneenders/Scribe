public struct Frame: Codable, Sendable {

    public var frame: [Location: String] = [:]
    public let maxX: Int
    public let maxY: Int

    public init(_ maxX: Int, _ maxY: Int) {
        self.maxX = maxX
        self.maxY = maxY
        for y in 1...maxY {
            for x in 1...maxX {
                frame[Location(x, y)] = "#"
            }
        }
    }
}
