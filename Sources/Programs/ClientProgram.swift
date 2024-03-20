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
    private var x: Int = 80
    private var y: Int = 24

    private var page: Page
    private var state: State = .select

    public init() async {
        self.page = Page([["ClientProgram"], ["Not Connected"]])
    }

    private func handle(_ msg: String) {
        let s = ServerMessage(json: msg)
        switch s.type {
        case .disconnect:
            self.state = .select
            self.frame = self.page.renderWindow(self.x, self.y)
        case .frame(let f):
            self.frame = f
        case .upload:
            print("\(self) upload")
        }
    }

    public func command(
        with action: Command<ClientAction>, _ maxX: Int, _ maxY: Int
    ) async {
        self.x = maxX
        self.y = maxY
        switch (self.status, self.state, action) {
        case (.working, .select, .action(.key(let k))):
            switch k {
            case .ctrlC:
                self.status = .close
                self.state = .select
                self.frame = page.renderWindow(maxX, maxY)
            case .ctrlJ:
                do {
                    let host = "::1"
                    let port = 42169
                    let box = try await ClientBox(
                        host: host, port: port, handle(_:))
                    let clientMsg = ClientMessage(
                        connect: "IDK", maxX: maxX, maxY: maxY)
                    try await box.client.write(msg: clientMsg.json)
                    self.state = .connected(box, 1)
                } catch {
                    print("\(self) unable to create \(ClientBox.self)")
                }
            default:
                self.frame = page.renderWindow(maxX, maxY)
            }
        case (.working, .connected(let b, let i), .action(.key(let k))):
            let clientMsg = ClientMessage(
                ascii: k.rawValue, maxX: maxX, maxY: maxY)
            do {
                try await b.client.write(msg: clientMsg.json)
            } catch {
                print("failed to send: \(clientMsg) to \(b)")
                self.state = .select
            }
        default:
            self.frame = page.renderWindow(maxX, maxY)
        }
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
    case connected(ClientBox, Int)
}
