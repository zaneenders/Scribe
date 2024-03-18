import NIOCore
import NIOPosix
import Shared

actor ClientConnction {

    private let outbound: NIOAsyncChannelOutboundWriter<String>
    private let inbound: NIOAsyncChannelInboundStream<String>
    private let address: String
    private let scribe: Scribe

    init(
        _ programs: [any Program.Type],
        _ address: String,
        _ inbound: NIOAsyncChannelInboundStream<String>,
        _ outbound: NIOAsyncChannelOutboundWriter<String>
    ) {
        self.address = address
        self.outbound = outbound
        self.inbound = inbound
        self.scribe = Scribe(programs)
    }

    func handleConnection() async {
        do {
            for try await inboundData in inbound {
                let msg: ServerMessage
                let clientMsg = ClientMessage(json: inboundData)
                switch clientMsg.command {
                case let .ascii(b, maxX: x, maxY: y):
                    guard let ascii = AsciiKeyCode.decode(keyboard: b) else {
                        msg = ServerMessage()
                        try await outbound.write(msg.json)
                        outbound.finish()
                        return
                    }
                    let frame = await self.scribe.getFrame(.key(ascii), x, y)
                    switch await self.scribe.state {
                    case .running:
                        msg = ServerMessage(frame: frame)
                    case .shutdown:
                        msg = ServerMessage()
                        try await outbound.write(msg.json)
                        outbound.finish()
                        print("goodbye")
                        return
                    }
                case let .connect(c, maxX: x, maxY: y):
                    print(c)
                    let frame = await self.scribe.getFrame(.hello, x, y)
                    msg = ServerMessage(frame: frame)
                }
                try await outbound.write(msg.json)
            }
        } catch {
            print("processing error \(error.localizedDescription)")
        }
    }
}
