import NIOCore
import NIOPosix

public struct MessageClient: ~Copyable {

    private let channel: any Channel

    public var address: String {
        if let addres = channel.localAddress {
            return "\(addres)"
        } else {
            return "CLIENT ERROR"
        }
    }

    public func write(msg: String) async throws {
        do {
            try await channel.writeAndFlush(msg)
        } catch {
            throw ClientError.send("\(error)")
        }
    }

    public func close() async {
        try? await channel.close().get()
    }

    public init(
        host: String = "::1", port: Int = 42069,
        _ handle: @escaping (String) -> Void
    ) async throws {
        let eventGroup: MultiThreadedEventLoopGroup = .singleton
        do {
            self.channel = try await ClientBootstrap(group: eventGroup)
                .channelOption(
                    ChannelOptions.socketOption(.so_reuseaddr), value: 1
                )
                .channelInitializer { channel in
                    channel.eventLoop.makeCompletedFuture {
                        let msgHandler = MessageDelgator<String, String>(handle)
                        let msgDecoder = ByteToMessageHandler(MessageReader())
                        let msgEncoder = MessageToByteHandler(MessageReader())
                        try channel.pipeline.syncOperations.addHandlers(
                            [
                                msgDecoder,
                                msgEncoder,
                                msgHandler,
                            ])
                    }
                }
                .connect(host: host, port: port).get()
        } catch {
            throw ClientError.connect("\(error)")
        }
    }
}

extension MessageClient {
    public enum ClientError: Error {
        case send(String)
        case connect(String)
    }
}

extension MessageClient {

    private final class MessageDelgator<Request, Response>:
        ChannelDuplexHandler
    {

        typealias InboundOut = Never
        typealias InboundIn = Response
        typealias OutboundOut = Request
        typealias OutboundIn = Request

        private let handle: (Response) -> Void

        init(_ handle: @escaping (Response) -> Void) {
            self.handle = handle
        }

        public func write(
            context: ChannelHandlerContext, data: NIOAny,
            promise: EventLoopPromise<Void>?
        ) {
            let request = self.unwrapOutboundIn(data)
            context.write(self.wrapOutboundOut(request), promise: promise)
        }

        public func channelRead(context: ChannelHandlerContext, data: NIOAny) {
            let response = self.unwrapInboundIn(data)
            handle(response)
        }
    }
}

extension MessageClient {

    private final class MessageHandler<Request, Response>:
        ChannelDuplexHandler
    {

        typealias InboundOut = Never
        typealias InboundIn = Response
        typealias OutboundOut = Request
        typealias OutboundIn = (Request, EventLoopPromise<Response>)

        init() {}

        private var pending: CircularBuffer<EventLoopPromise<Response>> =
            CircularBuffer(initialCapacity: 6)

        public func write(
            context: ChannelHandlerContext, data: NIOAny,
            promise: EventLoopPromise<Void>?
        ) {
            let (request, responsePromise) = self.unwrapOutboundIn(data)
            self.pending.append(responsePromise)
            context.write(self.wrapOutboundOut(request), promise: promise)
        }

        public func channelRead(context: ChannelHandlerContext, data: NIOAny) {
            let response = self.unwrapInboundIn(data)
            let promise = self.pending.removeFirst()
            promise.succeed(response)
        }
    }
}
