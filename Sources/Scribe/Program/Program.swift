public typealias InputType = AsciiKeyCode

public protocol Action: Sendable {}

extension Program {
    public static var name: String {
        "\(self)"
    }
}

public protocol Program: Sendable {
    associatedtype ActionType: Action
    init() async

    // this is static as to try and isolate from key logging
    // and enforce the abstraction away from input types and
    // only use action types
    // This also separates the preferences of what key maps
    // to what action
    static func processKey(_ key: InputType) -> ActionType

    func getFrame(
        with action: ActionType, _ maxX: Int, _ maxY: Int
    ) async -> Frame

    func getStatus() async -> Status
}

public enum Status: Sendable {
    case working
    case close
}
