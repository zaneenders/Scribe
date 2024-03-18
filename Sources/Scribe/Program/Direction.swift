public enum Direction: Codable, Sendable {
    case up
    case down
    case left
    case right
}

extension Location {
    public func get(_ dir: Direction) -> Location {
        switch dir {
        case .up:
            Location(self.x, self.y - 1)
        case .down:
            Location(self.x, self.y + 1)
        case .left:
            Location(self.x - 1, self.y)
        case .right:
            Location(self.x + 1, self.y)
        }
    }
}
