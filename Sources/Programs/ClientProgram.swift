import Scribe

public enum ClientAction: Action {
    case key(AsciiKeyCode)
    case hello
}

public actor ClientProgram: Program {
    public typealias ActionType = ClientAction

    var page: Page
    var status: Status = .working
    private var state: State = .select

    public init() async {
        self.page = Page([["ClientProgram"], ["Not Connected"]])
    }

    private enum State {
        case select
        case connected(Box, Int)
    }

    private final class Box {
        init(host: String = "::1", port: Int = 42169) async throws {
            self.client = try await MessageClient(
                host: host, port: port, { _ in })
        }
        let client: MessageClient
    }

    public func getStatus() async -> Status {
        self.status
    }

    public func getFrame(
        with action: ClientAction, _ maxX: Int, _ maxY: Int
    ) async -> Frame {
        return page.renderWindow(maxX, maxY)
    }

    public static func processKey(_ key: InputType) -> ClientAction {
        ClientAction.key(key)
    }
}
