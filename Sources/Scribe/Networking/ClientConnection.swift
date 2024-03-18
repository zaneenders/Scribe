import NIOCore
import NIOPosix
import Shared

actor ClientConnction {
    private let outbound: NIOAsyncChannelOutboundWriter<String>
    private let inbound: NIOAsyncChannelInboundStream<String>
    private let address: String
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
            for try await inboundData in inbound {
                print(inboundData)
                let msg: ServerMessage
                let clientMsg = ClientMessage(json: inboundData)
                switch clientMsg.command {
                case let .byte(b, maxX: x, maxY: y):
                    if "\(b)" == "3" {
                        msg = ServerMessage()
                    } else {
                        msg = ServerMessage(frame: Frame(x, y))
                    }
                case let .connect(c, maxX: x, maxY: y):
                    msg = ServerMessage(frame: Frame(x, y))
                }
                try await outbound.write(msg.json)
            }
        } catch {
            print("processing error \(error.localizedDescription)")
        }
    }
}
