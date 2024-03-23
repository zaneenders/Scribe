import NIOFileSystem
import Scribe

public enum NetworkedFilesAction: Action {
    case key(AsciiKeyCode)
}

public actor NetworkedFiles: Program {

    public typealias ActionType = NetworkedFilesAction

    public static func processKey(_ key: InputType) -> Command<
        NetworkedFilesAction
    > {
        .action(.key(key))
    }

    private(set) var status: Status = .working
    private var state: State = .ready
    private(set) var frame: Frame = Frame(80, 24)
    private var page: Page
    private var x: Int = 80
    private var y: Int = 24

    public init() async {
        self.page = Page([["NetworkedFiles"], ["NetworkedFiles"]])
    }

    private func handle(_ json: String) {
        let msg = ServerMessage(json: json)
        switch msg.type {
        case .frame(_), .disconnect:
            ()
        case .upload(data: let str):
            print("\(self)Data recieved: \(str.count)")
            let store = Storage(data: str)
            self.state = .hasDownload(store)
        }
    }

    public func command(
        with action: Command<NetworkedFilesAction>, _ maxX: Int, _ maxY: Int
    ) async {
        self.x = maxX
        self.y = maxY
        switch (self.status, action) {
        case (.working, .action(.key(let k))):
            switch k {
            case .ctrlC:
                switch self.state {
                case .connected(let b, _):
                    let dis = ClientMessage(disconnect: "")
                    try? await b.client.write(msg: dis.json)
                    print("closing \(b)")
                    self.state = .ready
                case .ready:
                    self.status = .close
                case .hasDownload(_):
                    print("download lost")
                    self.state = .ready
                }
            case .ctrlR:
                ()
            // data race
            // try? await other("::1", 42020)
            case .ctrlJ:
                switch self.state {
                case .connected(let client, _):
                    // downlaod message
                    let msg = ClientMessage(download: "Zane was here")
                    do {
                        try await client.client.write(msg: msg.json)
                        print("Message sent")
                    } catch {
                        print("unable to send \(msg)")
                    }
                    print("closing: \(client)")
                // try? await client.client.close()

                case .ready:
                    let host = "::1"
                    let port = 42169
                    do {
                        self.state = try await .connected(
                            ClientBox(host: host, port: port, handle), 0)
                        print("Connected to \(host): \(port)")
                    } catch {
                        print("Failed to connect to \(host): \(port)")
                    }
                case .hasDownload(let store):
                    let ops: OpenOptions.Write = .newFile(replaceExisting: true)
                    let path = FilePath(
                        "/home/zane/.scribe/Packages/Scribe/download.txt")
                    do {

                        let fh = try await FileSystem.shared.openFile(
                            forWritingAt: path, options: ops)
                        var writer: BufferedWriter = fh.bufferedWriter()
                        let bytes = Array(store.data.utf8)
                        print("writing bytes \(bytes.count)")
                        try await writer.write(
                            contentsOf: bytes)
                        try await writer.flush()
                        try await fh.close()
                        print("download complete")
                        self.state = .ready
                    } catch {
                        print("error writing file \(path)")
                    }
                    self.state = .ready
                }
            default:
                ()
            }
        default:
            ()
        }
        self.frame = page.renderWindow(self.x, self.y)
    }

    public func getFrame() async -> Frame {
        page.renderWindow(self.x, self.y)
    }

    public func getStatus() async -> Status {
        self.status
    }
}

private final class Storage {
    init(data: String) {
        self.data = data
    }
    let data: String
}

private enum State {
    case ready
    case connected(ClientBox, Int)
    case hasDownload(Storage)
}
