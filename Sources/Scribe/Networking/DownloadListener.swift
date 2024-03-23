import NIOFileSystem

@globalActor
actor DownloadManager {
    static let shared: DownloadManager = DownloadManager()

    init() {}
}

actor DownloadConnection {

    var writer: ((String) async throws -> Void)!
    private let address: String
    init(_ address: String) {
        self.address = address
        print("DownloadConnection[\(address)] init")
    }
    deinit {
        print("DownloadConnection[\(address)] deinit")
    }

    func setWriter(_ writer: @Sendable @escaping (String) async throws -> Void)
    {
        self.writer = writer
    }

    func read(_ json: String) async throws {
        if let file = FilesMessage(json: json) {
            print("DownloadConnection[\(address)]: \(file.type)")
            switch file.type {
            case .request(let name):
                let test = "/home/zane/.scribe/test"
                let path: FilePath = FilePath(test)
                do {
                    let fh = try await FileSystem.shared.openFile(
                        forReadingAt: path)

                    if let info = try? await fh.info() {
                        if var data = try? await fh.readToEnd(
                            maximumSizeAllowed: .bytes(info.size))
                        {
                            if let str = data.readString(length: Int(info.size))
                            {
                                let msg = ServerMessage(upload: str)
                                try? await writer(msg.json)
                            }
                        }
                    }
                    try await fh.close()
                    print("File: \(name) sent")
                } catch {
                    print(error.localizedDescription)
                    print("un able to send \(name)")
                }
            case .file(data:):
                ()
            }
        } else {
            print("DownloadConnection[\(address)]: \(json)")
        }
    }
}
