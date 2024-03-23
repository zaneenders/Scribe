actor Reciever {

    var writer: ((String) async throws -> Void)!
    private var scribe: Scribe
    private let address: String

    init(_ address: String, _ programs: [any Program.Type]) {
        self.scribe = Scribe(address, programs)
        self.address = address
        print("Reciever[\(address)] init")
    }
    deinit {
        print("Reciever[\(address)] deinit")
    }

    func setWrter(_ writer: @Sendable @escaping (String) async throws -> Void) {
        self.writer = writer
    }

    func read(_ json: String) async throws {
        if let clientMsg = ClientMessage(json: json) {
            try await handle(clientMsg)
        }
    }

    private func handle(_ msg: ClientMessage) async throws {
        let rsp: ServerMessage
        switch msg.command {
        case .disconnect:
            rsp = ServerMessage()
        case let .download(name: _):
            rsp = ServerMessage()
        case let .ascii(b, maxX: x, maxY: y):
            if let code = AsciiKeyCode.decode(keyboard: b) {
                switch code {
                case .ctrlC:
                    rsp = ServerMessage()
                default:
                    rsp = ServerMessage(frame: Frame(x, y))
                }
            } else {
                rsp = ServerMessage()
            }
        case let .connect(_, maxX: x, maxY: y):
            rsp = ServerMessage(frame: Frame(x, y))
        }
        print(msg.json)
        try await writer(rsp.json)
    }
}
