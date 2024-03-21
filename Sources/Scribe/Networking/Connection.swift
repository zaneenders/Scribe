import NIOCore
import NIOPosix

actor Connection {

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

    private let scribe: Scribe
    private let address: String
    private let inbound: NIOAsyncChannelInboundStream<String>
    private let outbound: NIOAsyncChannelOutboundWriter<String>
    private var connected = true

    private func disconnect() {
        self.connected = false
    }

    private func current() async -> Frame {
        return await self.scribe.frame()
    }

    func mainloop() async throws {
        try await withThrowingDiscardingTaskGroup { group in
            group.addTask {
                // handling incoming messages
                for try await msg in self.inbound {
                    print(msg)

                    let request = ClientMessage(json: msg)
                    switch request.command {
                    case let .ascii(b, maxX: x, maxY: y):
                        guard let ascii = AsciiKeyCode.decode(keyboard: b)
                        else {
                            continue
                        }
                        await self.scribe.command(.key(ascii), x, y)
                        switch await self.scribe.state {
                        case .running:
                            ()
                        case .shutdown:
                            let msg = ServerMessage()
                            try await self.outbound.write(msg.json)
                            await self.disconnect()
                            return
                        }
                    case .disconnect:
                        print("please dissconnect")
                        let msg = ServerMessage()
                        try await self.outbound.write(msg.json)
                        await self.disconnect()
                        return
                    case let .connect(_, maxX: x, maxY: y):
                        await self.scribe.command(.hello, x, y)
                    case .download(let name):
                        let handler = DownloadHandler(self.outbound)
                        await handler.download(name)
                        print("please dissconnect downloader")
                        let msg = ServerMessage()
                        try await self.outbound.write(msg.json)
                        await self.disconnect()
                        return
                    }
                }
            }

            group.addTask {
                // handle outgoing messages
                while await self.connected {
                    let msg = await ServerMessage(frame: self.current())
                    try? await self.outbound.write(msg.json)
                    try? await Task.sleep(for: .milliseconds(33))
                }
            }
        }
    }
}
