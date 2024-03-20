import Foundation
import NIOCore
import NIOPosix

public protocol ScribeServer {
    init()
    var programs: [any Program.Type] { get }
}

extension ScribeServer {
    public static func main() async throws {
        let s = self.init()
        // Just always run in the same location
        let programs = s.programs
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
        let mainChannel:
            NIOAsyncChannel<NIOAsyncChannel<String, String>, Never> =
                try await bootstrap.bind(
                    host: host,
                    port: port
                ) { channel in
                    channel.eventLoop.makeCompletedFuture {
                        let msgDecoder = ByteToMessageHandler(
                            MessageReader())
                        let msgEncoder = MessageToByteHandler(
                            MessageReader())
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
        let otherChannel:
            NIOAsyncChannel<NIOAsyncChannel<String, String>, Never> =
                try await bootstrap.bind(
                    host: host,
                    port: port + 1
                ) { channel in
                    channel.eventLoop.makeCompletedFuture {
                        let msgDecoder = ByteToMessageHandler(
                            MessageReader())
                        let msgEncoder = MessageToByteHandler(
                            MessageReader())
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

        try await withThrowingDiscardingTaskGroup { group in
            group.addTask {
                // Crash if server does not have local address
                let localAddress = mainChannel.channel.localAddress!
                print("\(Self.self) running: \(localAddress)")
                try await withThrowingDiscardingTaskGroup { group in
                    try await mainChannel.executeThenClose { inbound in
                        for try await connection in inbound {
                            group.addTask {
                                try await _handleConnection(
                                    connection, programs)
                            }
                        }
                    }
                }
            }
            if false {
                group.addTask {
                    // Crash if server does not have local address
                    let localAddress = otherChannel.channel.localAddress!
                    print("\(Self.self) running: \(localAddress)")

                    try await withThrowingDiscardingTaskGroup { group in
                        try await otherChannel.executeThenClose { inbound in
                            for try await connection in inbound {
                                group.addTask {

                                    try await connection.executeThenClose {
                                        inbound, outbound in
                                        for try await msg in inbound {
                                            print(msg)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private static func _handleConnection(
        _ channel: NIOAsyncChannel<String, String>,
        _ programs: [any Program.Type]
    ) async throws {
        try await channel.executeThenClose { inbound, outbound in
            if let address = channel.channel.remoteAddress {
                let connection = Connection(
                    programs, "\(address)", inbound, outbound)
                try await connection.mainloop()
            }
        }
    }
}
