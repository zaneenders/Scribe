public struct Location: Hashable, Codable, Sendable {
    public let x: Int
    public let y: Int

    public init(_ x: Int, _ y: Int) {
        self.x = x
        self.y = y
    }
}

extension Location: Comparable {
    // Top Left to bottom right
    public static func < (lhs: Location, rhs: Location) -> Bool {
        if lhs.y == rhs.y {
            if lhs.x <= rhs.x {
                return true
            } else {
                return false
            }
        } else if lhs.y < rhs.y {
            return true
        } else {
            return false
        }
    }
}
