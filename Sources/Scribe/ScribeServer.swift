import Foundation
import NIOCore
import NIOPosix
import Shared

public protocol ScribeServer {
    init()
}

extension ScribeServer {
    public static func main() async throws {
        let s = self.init()
        // Just always run in the same location
        let home = FileManager.default.homeDirectoryForCurrentUser
        FileManager.default.changeCurrentDirectoryPath(home.path + "/.scribe")
        let args = CommandLine.arguments
        let host: String
        let port: Int
        if args.count >= 3 {
            host = args[1]
            port = Int(args[2])!
        } else {
            host = "::1"
            port = 42069
        }
        let eventLoopGroup: MultiThreadedEventLoopGroup = .singleton
        let bootstrap = ServerBootstrap(group: eventLoopGroup)
            .serverChannelOption(
                ChannelOptions.socketOption(.so_reuseaddr), value: 1
            )
        let asyncChannel:
            NIOAsyncChannel<NIOAsyncChannel<String, String>, Never> =
                try await bootstrap.bind(
                    host: host,
                    port: port
                ) { channel in
                    channel.eventLoop.makeCompletedFuture {
                        let msgDecoder = ByteToMessageHandler(MessageReader())
                        let msgEncoder = MessageToByteHandler(MessageReader())
                        try channel.pipeline.syncOperations.addHandlers(
                            [
                                msgDecoder,
                                msgEncoder,
                            ])
                        return try NIOAsyncChannel(
                            wrappingChannelSynchronously: channel,
                            configuration:
                                NIOAsyncChannel.Configuration(
                                    inboundType: String.self,
                                    outboundType: String.self
                                )
                        )
                    }
                }
        let localAddress = asyncChannel.channel.localAddress!
        print("\(Self.self) running: \(localAddress)")
        try await withThrowingDiscardingTaskGroup { group in
            try await asyncChannel.executeThenClose { inbound in
                for try await connectionChannel in inbound {
                    group.addTask {
                        if let clientAddress = connectionChannel.channel
                            .remoteAddress
                        {
                            do {
                                print("\(clientAddress): Connected")
                                try await connectionChannel.executeThenClose {
                                    inbound, outbound in
                                    let client = ClientConnction(
                                        "\(clientAddress)",
                                        inbound, outbound)
                                    await client.handleConnection()
                                    outbound.finish()
                                }
                                print("\(clientAddress): Disconnected")
                            } catch {
                                fatalError("ConnectionError: \(error)")
                            }
                        } else {
                            print(
                                "failed to get clientAddress \(connectionChannel)"
                            )
                        }
                    }
                }
            }
        }
    }
}
