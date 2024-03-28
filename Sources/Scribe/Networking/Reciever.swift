actor Reciever {

    var writer: ((String) async throws -> Void)!
    private var scribe: BlockScribe
    private let address: String

    init(_ address: String, _ programs: [any Program.Type]) {
        self.scribe = BlockScribe(address, programs)
        self.address = address
        print("Reciever[\(address)] init")
    }
    deinit {
        print("Reciever[\(address)] deinit")
    }

    func setWriter(_ writer: @Sendable @escaping (String) async throws -> Void)
    {
        self.writer = writer
    }

    func read(_ json: String) async throws {
        if let clientMsg = TerminalMessage(json: json) {
            try await handle(clientMsg)
        }
    }

    private func handle(_ msg: TerminalMessage) async throws {
        let rsp: ServerMessage
        switch msg.command {
        case let .ascii(b, maxX: x, maxY: y):
            if let code = AsciiKeyCode.decode(keyboard: b) {
                await self.scribe.command(.key(code), x, y)
                switch await self.scribe.state {
                case .running:
                    rsp = await ServerMessage(frame: self.scribe.frame())
                case .shutdown:
                    rsp = ServerMessage()
                }
            } else {
                rsp = ServerMessage()
            }
        case let .connect(_, maxX: x, maxY: y):
            await self.scribe.command(.hello, x, y)
            switch await self.scribe.state {
            case .running:
                rsp = await ServerMessage(frame: self.scribe.frame())
            case .shutdown:
                rsp = ServerMessage()
            }
        }
        try await writer(rsp.json)
    }
}
