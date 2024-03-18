import Foundation
import Scribe

extension Frame {
    func printASCII() {
        var out = ""
        for y in 1...maxY {
            for x in 1...maxX {
                out += String(frame[Location(x, y)]!)
            }
            if y != maxY {
                out += "\n"
            }
        }
        print(clearCode, terminator: "")
        print(out, terminator: "")
    }
}

@MainActor
private func render(_ msg: ServerMessage) {
    switch msg.type {
    case .disconnect:
        cleanup()
        exit(0)
    case .frame(let f):
        f.printASCII()
    }
}

@main
struct Client {
    public static func main() async {
        let host: String
        let port: Int
        let args = CommandLine.arguments
        if args.count >= 3 {
            host = args[1]
            port = Int(args[2])!
        } else {
            host = "::1"
            port = 42069
        }
        do {
            let client = try await MessageClient(host: host, port: port)
            try await mainLoop(client)
        } catch {
            print("failed to connect: \(error)")
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
                y: Int(w.ws_row.magnitude))  // Ugh Alacrity
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

@MainActor
var cleanup: () -> Void = {}

@MainActor
private func mainLoop(_ client: consuming MessageClient) async throws {

    var raw: termios = initCStruct()
    let std_fd = FileHandle.standardInput.fileDescriptor
    tcgetattr(std_fd, &raw)  // save current profile
    let originalConfig = raw
    let reset = {
        // restore on release
        var term = originalConfig
        tcsetattr(std_fd, TCSAFLUSH, &term)

        print(clearCode, terminator: "")
        print(
            AnsiCode.Cursor.show.rawValue + AnsiCode.reset.rawValue,
            terminator: "")
        print("Scribe: Goodbye")
    }

    cleanup = reset

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
    do {
        try await connect(client)
    } catch {
        cleanup()
        print(error.localizedDescription)
        exit(0)
    }
    let std: FileHandle = FileHandle.standardInput
    for try await byte in std.asyncByteIterator() {
        let size = TerminalSize.size()
        do {
            let clientMsg = ClientMessage(
                ascii: byte, maxX: size.x, maxY: size.y)
            let r = try await client.send(msg: clientMsg.json)
            let serverMsg = ServerMessage(json: r)
            render(serverMsg)
        } catch {
            cleanup()
            print(error.localizedDescription)
            exit(0)
        }
    }
}

func connect(_ client: MessageClient) async throws {
    let size = TerminalSize.size()
    let clientMsg = ClientMessage(
        connect: client.address, maxX: size.x, maxY: size.y)
    let r = try await client.send(msg: clientMsg.json)
    let serverMsg = ServerMessage(json: r)
    await render(serverMsg)
}
