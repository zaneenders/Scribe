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
        try await withThrowingDiscardingTaskGroup { group in
            group.addTask {
                try? await listen(on: host, port, programs)
            }
        }
    }
}

func listen(on host: String, _ port: Int, _ programs: [any Program.Type])
    async throws
{
    let eventLoopGroup: MultiThreadedEventLoopGroup = .singleton
    let bootstrap = ServerBootstrap(group: eventLoopGroup)
        .serverChannelOption(
            ChannelOptions.socketOption(.so_reuseaddr), value: 1
        )

    let otherChannel: NIOAsyncChannel<NIOAsyncChannel<String, String>, Never> =
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

    let localAddress = otherChannel.channel.localAddress!
    print("Listening on: \(localAddress)")

    try await withThrowingDiscardingTaskGroup { group in
        try await otherChannel.executeThenClose { inbound in
            for try await connection in inbound {
                group.addTask {
                    guard let remoteAddress = connection.channel.remoteAddress
                    else {
                        return
                    }
                    let test = Reciever("\(remoteAddress)", programs)
                    try await connection.executeThenClose {
                        inbound, outbound in
                        print("[\(remoteAddress)] connected")

                        @Sendable
                        func writer(_ json: String) async throws {
                            try await outbound.write(json)
                        }

                        await test.setWriter(writer(_:))
                        for try await msg in inbound {
                            try await test.read(msg)
                        }
                        print("[\(remoteAddress)] disconnected")
                    }
                }
            }
        }
    }
}
