import NIOCore
import NIOPosix

public final class MessageReader:
    ByteToMessageDecoder,
    MessageToByteEncoder
{

    public typealias InboundOut = String
    public typealias InboundIn = ByteBuffer

    public init() {}

    private let split = UInt8(ascii: "\n")

    public func encode(data: String, out: inout ByteBuffer) throws {
        out.writeString(data)
        out.writeInteger(split)
    }

    public func decode(context: ChannelHandlerContext, buffer: inout ByteBuffer)
        throws
        -> DecodingState
    {
        let bytes: ByteBufferView = buffer.readableBytesView
        guard let index: ByteBufferView.Index = bytes.firstIndex(of: split)
        else {
            return .needMoreData
        }
        let msgSequence: ByteBufferView.SubSequence = bytes[..<index]
        buffer.moveReaderIndex(forwardBy: msgSequence.count + 1)
        let msgBuffer = ByteBuffer(msgSequence)
        let msg = String(buffer: msgBuffer)
        context.fireChannelRead(self.wrapInboundOut(msg))
        return .continue
    }
}
