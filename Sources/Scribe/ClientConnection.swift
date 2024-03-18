import NIOCore
import NIOPosix

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
                try await outbound.write("Server: \(inboundData)")
            }
        } catch {
            print("processing error \(error.localizedDescription)")
        }
    }
}
