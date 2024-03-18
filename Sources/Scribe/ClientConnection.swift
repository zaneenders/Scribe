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
                case .byte(let b, maxX: _, maxY: _):
                    if "\(b)" == "3" {
                        msg = ServerMessage()
                    } else {
                        msg = ServerMessage(msg: "Server: \(inboundData)")
                    }
                case .connect(let c, maxX: _, maxY: _):
                    msg = ServerMessage(msg: "\(c)")
                }
                try await outbound.write(msg.json)
            }
        } catch {
            print("processing error \(error.localizedDescription)")
        }
    }
}
