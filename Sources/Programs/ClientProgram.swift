import Scribe

public enum ClientAction: Action {
    case key(AsciiKeyCode)
}

public actor ClientProgram: Program {

    public typealias ActionType = ClientAction

    public static func processKey(_ key: InputType) -> Command<ClientAction> {
        .action(.key(key))
    }

    private(set) var status: Status = .working
    private(set) var frame: Frame = Frame(80, 24)

    private var page: Page
    private var state: State = .select

    public init() async {
        self.page = Page([["ClientProgram"], ["Not Connected"]])
    }

    public func command(
        with action: Command<ClientAction>, _ maxX: Int, _ maxY: Int
    ) async {
        switch action {
        case .hello:
            ()
        case .action(.key(.ctrlC)):
            self.status = .close
        default:
            do {
                let box = try await Box({ _ in })
            } catch {
                print("\(self) unable to create \(Box.self)")
            }
        }
        self.frame = page.renderWindow(maxX, maxY)
    }

    public func getFrame() async -> Frame {
        self.frame
    }

    public func getStatus() async -> Status {
        self.status
    }
}

private enum State {
    case select
    case connected(Box, Int)
}

private final class Box {

    let client: MessageClient

    init(
        host: String = "::1", port: Int = 42169,
        _ handle: @escaping (String) -> Void
    ) async throws {
        self.client = try await MessageClient(
            host: host, port: port, handle)
    }
}
