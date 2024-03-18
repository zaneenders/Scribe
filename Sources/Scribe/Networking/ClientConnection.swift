import NIOCore
import NIOPosix
import Shared

actor ClientConnction {
    private let outbound: NIOAsyncChannelOutboundWriter<String>
    private let inbound: NIOAsyncChannelInboundStream<String>
    private let address: String
    private let scribe = Scribe()
    init(
        _ address: String,
        _ inbound: NIOAsyncChannelInboundStream<String>,
        _ outbound: NIOAsyncChannelOutboundWriter<String>
    ) {
        self.address = address
        self.outbound = outbound
        self.inbound = inbound
    }

    func handleConnection() async {
        do {
            let client = await ClientProgram()
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
                    let m = ClientProgram.processKey(ascii)
                    let frame = await client.getFrame(with: m, x, y)
                    switch await client.getStatus() {
                    case .working:
                        msg = ServerMessage(frame: frame)
                    case .close:
                        msg = ServerMessage()
                        try await outbound.write(msg.json)
                        outbound.finish()
                        print("goodbye")
                        return
                    }
                case let .connect(c, maxX: x, maxY: y):
                    print(c)
                    msg = ServerMessage(frame: Frame(x, y))
                }
                try await outbound.write(msg.json)
            }
        } catch {
            print("processing error \(error.localizedDescription)")
        }
    }
}
