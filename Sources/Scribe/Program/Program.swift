public typealias InputType = AsciiKeyCode

public protocol Action: Sendable {}

public enum Command<Action> {
    case hello
    case action(Action)
}

extension Program {
    public static var name: String {
        "\(self)"
    }
}

public protocol Program<ActionType>: Sendable {
    associatedtype ActionType: Action
    init() async

    // this is static as to try and isolate from key logging
    // and enforce the abstraction away from input types and
    // only use action types
    // This also separates the preferences of what key maps
    // to what action
    static func processKey(_ key: InputType) -> Command<ActionType>

    func getStatus() async -> Status
    func command(with action: Command<ActionType>, _ maxX: Int, _ maxY: Int)
        async
    func getFrame() async -> Frame
}

public enum Status: Sendable {
    case working
    case close
}
