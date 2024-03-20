import NIOCore
import NIOFileSystem
import NIOPosix

actor DownloadHandler {

    init(_ outbound: NIOAsyncChannelOutboundWriter<String>) {
        self.outbound = outbound
    }

    private let outbound: NIOAsyncChannelOutboundWriter<String>
    func download(_ name: String) async {
        print("download")
        let test = "/home/zane/.scribe/test"
        let path: FilePath = FilePath(test)
        do {
            let fh = try await FileSystem.shared.openFile(forReadingAt: path)

            if let info = try? await fh.info() {
                if var data = try? await fh.readToEnd(
                    maximumSizeAllowed: .bytes(info.size))
                {
                    if let str = data.readString(length: Int(info.size)) {
                        let msg = ServerMessage(upload: str)
                        try await outbound.write(msg.json)
                    }
                }
            }
            try await fh.close()
        } catch {
            print("un able to send upload")
        }
    }
}
