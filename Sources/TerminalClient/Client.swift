import Foundation
import NIOCore
import NIOPosix
import Scribe

@main
struct Client {
    public static func main() async throws {
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
        var raw: termios = initCStruct()
        let std_fd = FileHandle.standardInput.fileDescriptor
        tcgetattr(std_fd, &raw)  // save current profile
        let originalConfig = raw
        defer {
            // restore on release
            var term = originalConfig
            tcsetattr(std_fd, TCSAFLUSH, &term)

            print(clearCode, terminator: "")
            print(
                AnsiCode.Cursor.show.rawValue + AnsiCode.reset.rawValue,
                terminator: "")
            print("Scribe: Goodbye")
        }

        @Sendable
        func handle(_ msg: String) {
            let msg = ServerMessage(json: msg)
            switch msg.type {
            case .disconnect:
                // restore on release
                var term = originalConfig
                tcsetattr(std_fd, TCSAFLUSH, &term)

                print(clearCode, terminator: "")
                print(
                    AnsiCode.Cursor.show.rawValue + AnsiCode.reset.rawValue,
                    terminator: "")
                print("Scribe: Goodbye")
                exit(0)
            case .frame(let f):

                let size = TerminalSize.size()
                guard size.x == f.maxX && size.y == f.maxY else {
                    return
                }
                var out = ""
                for y in 1...f.maxY {
                    for x in 1...f.maxX {
                        out += String(f.frame[Location(x, y)]!)
                    }
                    if y != f.maxY {
                        out += "\n"
                    }
                }
                print(clearCode, terminator: "")
                print(out, terminator: "")
            case .upload:
                ()  // ignored, different client types?
            }
        }

        #if os(Linux)
            raw.c_lflag &= UInt32(~(UInt32(ECHO | ICANON | IEXTEN | ISIG)))
        #else  // MacOS
            raw.c_lflag &= UInt(~(UInt32(ECHO | ICANON | IEXTEN | ISIG)))
        #endif
        // apply raw mode to std in
        tcsetattr(std_fd, TCSAFLUSH, &raw)
        print(AnsiCode.Cursor.hide.rawValue, terminator: "")
        print(clearCode, terminator: "")
        print(AnsiCode.goTo(0, 0))

        let eventGroup: MultiThreadedEventLoopGroup = .singleton
        let channel = try await ClientBootstrap(group: eventGroup)
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
        do {
            let size = TerminalSize.size()
            guard let address = channel.localAddress else {
                return
            }
            let clientMsg = ClientMessage(
                connect: "\(address)", maxX: size.x, maxY: size.y)
            try await channel.writeAndFlush(clientMsg.json)
        } catch {
            // restore on release
            var term = originalConfig
            tcsetattr(std_fd, TCSAFLUSH, &term)

            print(clearCode, terminator: "")
            print(
                AnsiCode.Cursor.show.rawValue + AnsiCode.reset.rawValue,
                terminator: "")
            print("Scribe: Goodbye")
            print(error.localizedDescription)
            exit(0)
        }
        let std: FileHandle = FileHandle.standardInput
        for try await byte in std.asyncByteIterator() {
            let size = TerminalSize.size()
            do {
                let clientMsg = ClientMessage(
                    ascii: byte, maxX: size.x, maxY: size.y)
                try await channel.writeAndFlush(clientMsg.json)
            } catch {
                // restore on release
                var term = originalConfig
                tcsetattr(std_fd, TCSAFLUSH, &term)

                print(clearCode, terminator: "")
                print(
                    AnsiCode.Cursor.show.rawValue + AnsiCode.reset.rawValue,
                    terminator: "")
                print("Scribe: Goodbye")
                print(error.localizedDescription)
                exit(0)
            }
        }
    }
}

private struct TerminalSize {
    let x: Int
    let y: Int

    private init(x: Int, y: Int) {
        self.x = x
        self.y = y
    }

    static func size() -> TerminalSize {
        var w: winsize = initCStruct()
        _ = ioctl(STDOUT_FILENO, UInt(TIOCGWINSZ), &w)
        if w.ws_row == 0 || w.ws_col == 0 {
            print("error getting terminal size")
            return TerminalSize(x: -1, y: -1)
        } else {
            return TerminalSize(
                x: Int(w.ws_col.magnitude),
                y: Int(w.ws_row.magnitude))
        }
    }
}

private var clearCode: String {
    AnsiCode.eraseScreen.rawValue + AnsiCode.eraseSaved.rawValue
        + AnsiCode.Cursor.hide.rawValue + AnsiCode.home.rawValue
}

private func initCStruct<S>() -> S {
    let structPointer = UnsafeMutablePointer<S>.allocate(capacity: 1)
    let structMemory = structPointer.pointee
    structPointer.deallocate()
    return structMemory
}
