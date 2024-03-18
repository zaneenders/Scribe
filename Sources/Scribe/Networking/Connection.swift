import NIOCore
import NIOPosix

actor Connection {

    private let scribe: Scribe
    private let address: String
    private let inbound: NIOAsyncChannelInboundStream<String>
    private let outbound: NIOAsyncChannelOutboundWriter<String>

    init(
        _ programs: [any Program.Type],
        _ address: String,
        _ inbound: NIOAsyncChannelInboundStream<String>,
        _ outbound: NIOAsyncChannelOutboundWriter<String>
    ) {
        self.scribe = Scribe(address, programs)
        self.address = address
        self.inbound = inbound
        self.outbound = outbound
        print("\(self.address): Connected")
    }

    deinit {
        print("\(self.address): Disconnect")
    }

    private var connected = true
    private var x: Int = 80
    private var y: Int = 24

    private func update(_ x: Int, _ y: Int) {
        self.x = x
        self.y = y
    }

    private func disconnect() {
        self.connected = false
    }

    private func current() -> Frame {
        let t = ContinuousClock().now
        let page = Page([["Zane was here", "\(t)"]])
        return page.renderWindow(self.x, self.y)
    }

    func mainloop() async throws {
        try await withThrowingDiscardingTaskGroup { group in
            group.addTask {
                // handling incoming messages
                for try await msg in self.inbound {
                    let request = ClientMessage(json: msg)
                    switch request.command {
                    case let .ascii(b, maxX: x, maxY: y):
                        await self.update(x, y)
                        guard let ascii = AsciiKeyCode.decode(keyboard: b)
                        else {
                            continue
                        }
                        switch ascii {
                        case .ctrlC:
                            let msg = ServerMessage()
                            try await self.outbound.write(msg.json)
                            await self.disconnect()
                            return
                        default:
                            ()
                        }
                    case let .connect(_, maxX: x, maxY: y):
                        await self.update(x, y)
                    }
                }
            }

            group.addTask {
                // handle outgoing messages
                while await self.connected {
                    let msg = await ServerMessage(frame: self.current())
                    try? await self.outbound.write(msg.json)
                    try? await Task.sleep(for: .milliseconds(16))
                }
            }
        }
    }
}
